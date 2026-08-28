import sys

def patch_main():
    path = '/home/ubuntu/projects/humsukhan/lib/main.dart'
    with open(path, 'r') as f:
        content = f.read()

    # Add import
    if "import 'backend_provider.dart';" not in content:
        content = content.replace("import 'sherpa_speech.dart';", "import 'sherpa_speech.dart';\nimport 'backend_provider.dart';")

    # Update AppController fields
    if "final BackendProvider backend = BackendProvider();" not in content:
        content = content.replace(
            "final LocalStore store = LocalStore();",
            "final LocalStore store = LocalStore();\n  final BackendProvider backend = BackendProvider();"
        )

    # Update load method to init backend
    content = content.replace(
        "Future<void> load() async {",
        "Future<void> load() async {\n    await backend.init();"
    )

    # Update saveLocalAccount to use backend
    old_save_account = """  Future<void> saveLocalAccount({
    required String email,
    required String username,
    required String password,
    required LocalGender gender,
    String? displayName,
  }) async {
    final cleanEmail = email.trim();
    final cleanUsername = username.trim();
    final cleanDisplayName = (displayName ?? cleanUsername).trim();
    localEmail = cleanEmail;
    localUsername = cleanUsername;
    localDisplayName = cleanDisplayName.isEmpty ? cleanUsername : cleanDisplayName;
    localGender = gender;
    localAvatar = gender == LocalGender.female ? 'face' : 'person';
    // Only a salted digest is retained; the plaintext password never enters the store.
    final digest = sha256.convert(utf8.encode('humsukhan-local-v1:$cleanEmail:$password')).toString();
    localCredentialConfigured = password.trim().isNotEmpty;
    localLoginComplete = true;
    await store.set(
      'local_profile',
      jsonEncode({
        'display_name': localDisplayName,
        'username': localUsername,
        'email': localEmail,
        'gender': localGender.name,
        'avatar': localAvatar,
        'credential_configured': localCredentialConfigured,
        'credential_digest': digest,
        'login_complete': localLoginComplete,
      }),
    );
    notifyListeners();
  }"""

    new_save_account = """  Future<String?> saveLocalAccount({
    required String email,
    required String username,
    required String password,
    required LocalGender gender,
    bool isLogin = false,
    String? displayName,
  }) async {
    final cleanEmail = email.trim();
    final cleanUsername = username.trim();
    final cleanDisplayName = (displayName ?? cleanUsername).trim();
    
    bool success = false;
    if (isLogin) {
      success = await backend.login(cleanUsername, password);
    } else {
      success = await backend.register(cleanEmail, cleanUsername, password, gender.name);
    }

    if (!success) {
      return isLogin ? 'Invalid username or password.' : 'Could not create account. Username might be taken.';
    }

    localEmail = cleanEmail;
    localUsername = cleanUsername;
    localDisplayName = cleanDisplayName.isEmpty ? cleanUsername : cleanDisplayName;
    localGender = gender;
    localAvatar = gender == LocalGender.female ? 'face' : 'person';
    localCredentialConfigured = true;
    localLoginComplete = true;
    
    await store.set(
      'local_profile',
      jsonEncode({
        'display_name': localDisplayName,
        'username': localUsername,
        'email': localEmail,
        'gender': localGender.name,
        'avatar': localAvatar,
        'credential_configured': localCredentialConfigured,
        'login_complete': localLoginComplete,
      }),
    );
    
    // Trigger initial sync
    syncProfessionalData();
    
    notifyListeners();
    return null;
  }"""
    content = content.replace(old_save_account, new_save_account)

    # Add sync method
    sync_method = """
  Future<void> syncProfessionalData() async {
    if (!backend.isAuthenticated) return;
    
    // Push local records that might not be on server
    for (final record in records) {
      await backend.syncRecord(record);
    }
    
    // Pull from server
    final remoteRecords = await backend.getRecords();
    if (remoteRecords.isNotEmpty) {
      for (final remote in remoteRecords) {
        if (!records.any((r) => r.id == remote.id)) {
          records.add(remote);
        }
      }
      await persistRecords();
      notifyListeners();
    }
  }
"""
    if "Future<void> syncProfessionalData()" not in content:
        content = content.replace("Future<void> persistRecords() async {", sync_method + "\n  Future<void> persistRecords() async {")

    # Update persistRecords to sync
    content = content.replace(
        "await store.set('professional_records', jsonEncode(records.map((r) => r.toJson()).toList()));",
        "await store.set('professional_records', jsonEncode(records.map((r) => r.toJson()).toList()));\n    // Sync with backend if authenticated\n    if (activeRecord != null && backend.isAuthenticated) {\n      await backend.syncRecord(activeRecord!);\n    }"
    )

    # Update deleteProfessionalRecord to sync
    content = content.replace(
        "if (activeRecord?.id == record.id) activeRecord = null;\n    await persistRecords();",
        "if (activeRecord?.id == record.id) activeRecord = null;\n    if (backend.isAuthenticated) await backend.deleteRecord(record.id);\n    await persistRecords();"
    )

    # Update LocalSummarizationProvider to use backend
    old_summarization = """class LocalSummarizationProvider implements SummarizationProvider {
  static const _stopWords = {
    'about',
    'after',
    'again',
    'also',
    'could',
    'from',
    'have',
    'into',
    'just',
    'more',
    'need',
    'only',
    'please',
    'should',
    'that',
    'their',
    'there',
    'these',
    'they',
    'this',
    'through',
    'very',
    'were',
    'what',
    'when',
    'where',
    'which',
    'with',
    'would',
    'your',
    'okay',
    'understand',
  };

  @override
  Future<ProfessionalInsights> generate(List<TranscriptLine> transcript) async {
    final lines = transcript
        .map((line) => line.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();
    final source = lines.join(' ');
    final tokens = source
        .split(RegExp(r'[^\\p{L}\\p{N}\\-]+', unicode: true))
        .map((t) => t.toLowerCase())
        .where((t) => t.length > 3 && !_stopWords.contains(t))
        .toList();
    final counts = <String, int>{};
    for (final t in tokens) {
      counts[t] = (counts[t] ?? 0) + 1;
    }
    final vocabulary = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final actionItems = lines
        .where(
          (line) => RegExp(
            r'\\b(need to|should|must|action|follow up|next step|please|remember to)\\b',
            caseSensitive: false,
          ).hasMatch(line),
        )
        .take(5)
        .toList();
    final deadlines = lines
        .where(
          (line) => RegExp(
            r'\\b(today|tomorrow|monday|tuesday|wednesday|thursday|friday|saturday|sunday|by \\w+|\\d{1,2}[:/]\\d{1,2})\\b',
            caseSensitive: false,
          ).hasMatch(line),
        )
        .take(5)
        .toList();
    final people = <String>[];
    for (final line in lines) {
      for (final match in RegExp(
        r'\\b(?:Mr|Ms|Mrs|Dr)\\.?\\s+[A-Z][a-z]+',
      ).allMatches(line)) {
        if (!people.contains(match.group(0))) people.add(match.group(0)!);
      }
    }
    final summary = lines.isEmpty
        ? 'No transcript was captured.'
        : 'Captured ${lines.length} sentence${lines.length == 1 ? '' : 's'} across ${transcript.map((line) => line.speaker).toSet().length} speaker role${transcript.map((line) => line.speaker).toSet().length == 1 ? '' : 's'}. ${lines.take(2).join(' ')}';
    return ProfessionalInsights(
      summary: summary,
      vocabulary: vocabulary.isEmpty
          ? ['No repeated vocabulary detected']
          : vocabulary.take(8).map((entry) => entry.key).toList(),
      difficultTerms: vocabulary.take(3).map((entry) => entry.key).toList(),
      themes: [
        if (lines.any((line) => line.toLowerCase().contains('class'))) 'Class',
        if (lines.any((line) => line.toLowerCase().contains('meeting')))
          'Meeting',
        'Communication',
      ],
      actionItems: actionItems.isEmpty
          ? ['No explicit action item detected; review the transcript manually.']
          : actionItems,
      deadlines: deadlines.isEmpty
          ? ['No explicit deadline detected.']
          : deadlines,
      mentionedPeople: people.isEmpty
          ? ['No named person confidently detected.']
          : people,
    );
  }
}"""

    new_summarization = """class LocalSummarizationProvider implements SummarizationProvider {
  final BackendProvider? backend;
  LocalSummarizationProvider({this.backend});

  static const _stopWords = {
    'about', 'after', 'again', 'also', 'could', 'from', 'have', 'into', 'just', 'more', 'need', 'only', 'please', 'should', 'that', 'their', 'there', 'these', 'they', 'this', 'through', 'very', 'were', 'what', 'when', 'where', 'which', 'with', 'would', 'your', 'okay', 'understand',
  };

  @override
  Future<ProfessionalInsights> generate(List<TranscriptLine> transcript) async {
    if (backend != null && backend!.isAuthenticated) {
      final remote = await backend!.generateInsights(transcript);
      if (remote != null) return remote;
    }
    
    final lines = transcript.map((line) => line.text.trim()).where((text) => text.isNotEmpty).toList();
    final source = lines.join(' ');
    final tokens = source.split(RegExp(r'[^\\p{L}\\p{N}\\-]+', unicode: true)).map((t) => t.toLowerCase()).where((t) => t.length > 3 && !_stopWords.contains(t)).toList();
    final counts = <String, int>{};
    for (final t in tokens) { counts[t] = (counts[t] ?? 0) + 1; }
    final vocabulary = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final actionItems = lines.where((line) => RegExp(r'\\b(need to|should|must|action|follow up|next step|please|remember to)\\b', caseSensitive: false).hasMatch(line)).take(5).toList();
    final deadlines = lines.where((line) => RegExp(r'\\b(today|tomorrow|monday|tuesday|wednesday|thursday|friday|saturday|sunday|by \\w+|\\d{1,2}[:/]\\d{1,2})\\b', caseSensitive: false).hasMatch(line)).take(5).toList();
    final people = <String>[];
    for (final line in lines) { for (final match in RegExp(r'\\b(?:Mr|Ms|Mrs|Dr)\\.?\\s+[A-Z][a-z]+').allMatches(line)) { if (!people.contains(match.group(0))) people.add(match.group(0)!); } }
    final summary = lines.isEmpty ? 'No transcript was captured.' : 'Captured ${lines.length} sentence${lines.length == 1 ? '' : 's'} across ${transcript.map((line) => line.speaker).toSet().length} speaker role${transcript.map((line) => line.speaker).toSet().length == 1 ? '' : 's'}. ${lines.take(2).join(' ')}';
    return ProfessionalInsights(
      summary: summary,
      vocabulary: vocabulary.isEmpty ? ['No repeated vocabulary detected'] : vocabulary.take(8).map((entry) => entry.key).toList(),
      difficultTerms: vocabulary.take(3).map((entry) => entry.key).toList(),
      themes: [if (lines.any((line) => line.toLowerCase().contains('class'))) 'Class', if (lines.any((line) => line.toLowerCase().contains('meeting'))) 'Meeting', 'Communication'],
      actionItems: actionItems.isEmpty ? ['No explicit action item detected; review the transcript manually.'] : actionItems,
      deadlines: deadlines.isEmpty ? ['No explicit deadline detected.'] : deadlines,
      mentionedPeople: people.isEmpty ? ['No named person confidently detected.'] : people,
    );
  }
}"""
    content = content.replace(old_summarization, new_summarization)

    # Update AppController initialization of summarizationProvider
    content = content.replace(
        "final SummarizationProvider summarizationProvider = LocalSummarizationProvider();",
        "late final SummarizationProvider summarizationProvider = LocalSummarizationProvider(backend: backend);"
    )

    # Update LocalLoginScreen to support Login vs Register
    old_login_state = """class _LocalLoginScreenState extends State<LocalLoginScreen> {
  final email = TextEditingController();
  final username = TextEditingController();
  final password = TextEditingController();
  LocalGender gender = LocalGender.preferNotToSay;
  String? error;
  bool saving = false;"""

    new_login_state = """class _LocalLoginScreenState extends State<LocalLoginScreen> {
  final email = TextEditingController();
  final username = TextEditingController();
  final password = TextEditingController();
  LocalGender gender = LocalGender.preferNotToSay;
  String? error;
  bool saving = false;
  bool isLoginMode = false;"""

    content = content.replace(old_login_state, new_login_state)

    old_continue = """  Future<void> continueToGuide() async {
    final e = email.text.trim();
    final u = username.text.trim();
    final p = password.text;
    setState(() {
      error = e.contains('@') && e.contains('.') && u.length >= 2 && p.length >= 4
          ? null
          : 'Enter a valid email, a username, and a password of at least 4 characters.';
    });
    if (error != null) return;
    setState(() => saving = true);
    await widget.controller.saveLocalAccount(
      email: e,
      username: u,
      password: p,
      gender: gender,
    );
    if (mounted) setState(() => saving = false);
  }"""

    new_continue = """  Future<void> continueToGuide() async {
    final e = email.text.trim();
    final u = username.text.trim();
    final p = password.text;
    
    if (!isLoginMode) {
      setState(() {
        error = e.contains('@') && e.contains('.') && u.length >= 2 && p.length >= 4
            ? null
            : 'Enter a valid email, a username, and a password of at least 4 characters.';
      });
    } else {
      setState(() {
        error = u.length >= 2 && p.length >= 4
            ? null
            : 'Enter your username and password.';
      });
    }
    
    if (error != null) return;
    setState(() => saving = true);
    final apiError = await widget.controller.saveLocalAccount(
      email: e,
      username: u,
      password: p,
      gender: gender,
      isLogin: isLoginMode,
    );
    if (mounted) {
      setState(() {
        saving = false;
        error = apiError;
      });
    }
  }"""

    content = content.replace(old_continue, new_continue)

    # Update UI to toggle mode
    old_login_ui = """                Text('Create a private profile for this device. No cloud account or network sign-in is created.', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant), textAlign: TextAlign.center),
                const SizedBox(height: HKSpace.xl),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(HKSpace.lg),
                    child: Column(
                      children: [
                        TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email address', prefixIcon: Icon(Icons.alternate_email))),
                        const SizedBox(height: HKSpace.sm),
                        TextField(controller: username, decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.person_outline))),
                        const SizedBox(height: HKSpace.sm),
                        TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Password', helperText: 'Only a secure digest is kept on this device.', prefixIcon: Icon(Icons.lock_outline))),
                        const SizedBox(height: HKSpace.sm),
                        _DropdownField<LocalGender>(label: 'Gender for your first-start tutor', value: gender, values: LocalGender.values, labelOf: (value) => value.label, onChanged: (value) => setState(() => gender = value)),"""

    new_login_ui = """                Text(isLoginMode ? 'Sign in to your HumSukhan account to sync your data.' : 'Create a profile to sync your data and access AI features.', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant), textAlign: TextAlign.center),
                const SizedBox(height: HKSpace.xl),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(HKSpace.lg),
                    child: Column(
                      children: [
                        if (!isLoginMode) ...[
                          TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email address', prefixIcon: Icon(Icons.alternate_email))),
                          const SizedBox(height: HKSpace.sm),
                        ],
                        TextField(controller: username, decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.person_outline))),
                        const SizedBox(height: HKSpace.sm),
                        TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Password', helperText: 'Your data is encrypted and private.', prefixIcon: Icon(Icons.lock_outline))),
                        if (!isLoginMode) ...[
                          const SizedBox(height: HKSpace.sm),
                          _DropdownField<LocalGender>(label: 'Gender for your first-start tutor', value: gender, values: LocalGender.values, labelOf: (value) => value.label, onChanged: (value) => setState(() => gender = value)),
                        ],"""

    content = content.replace(old_login_ui, new_login_ui)

    content = content.replace(
        "label: Text(saving ? 'Saving locally…' : 'Continue to your guide')",
        "label: Text(saving ? (isLoginMode ? 'Signing in...' : 'Creating account...') : (isLoginMode ? 'Sign In' : 'Create Profile'))"
    )

    toggle_mode_ui = """                const SizedBox(height: HKSpace.sm),
                TextButton(
                  onPressed: () => setState(() {
                    isLoginMode = !isLoginMode;
                    error = null;
                  }),
                  child: Text(isLoginMode ? "Don't have an account? Create one" : "Already have an account? Sign in"),
                ),"""
    
    content = content.replace(
        "Text('You can edit your local profile later from Settings.', style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),",
        toggle_mode_ui + "\n                Text('You can edit your profile later from Settings.', style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),"
    )

    with open(path, 'w') as f:
        f.write(content)

if __name__ == "__main__":
    patch_main()
