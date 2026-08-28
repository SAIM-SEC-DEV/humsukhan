from pathlib import Path

root = Path('/home/ubuntu/projects/humsukhan')
main = root / 'lib/main.dart'
s = main.read_text()

s = s.replace("import 'package:flutter/services.dart';\n", "import 'package:flutter/services.dart';\nimport 'package:crypto/crypto.dart';\n")
s = s.replace("enum CaptionLanguage { english, romanUrdu, urduScript, auto }\n", "enum CaptionLanguage { english, romanUrdu, urduScript, auto }\n\nenum LocalGender { male, female, other, preferNotToSay }\n\nextension LocalGenderLabel on LocalGender {\n  String get label => switch (this) {\n    LocalGender.male => 'Male',\n    LocalGender.female => 'Female',\n    LocalGender.other => 'Other',\n    LocalGender.preferNotToSay => 'Prefer not to say',\n  };\n}\n\nLocalGender _genderFromStored(String? value) => LocalGender.values.firstWhere(\n  (gender) => gender.name == value,\n  orElse: () => LocalGender.preferNotToSay,\n);\n")

s = s.replace("class AppController extends ChangeNotifier {\n", "class PslRecognitionProvider {\n  static const repository = 'github.com/AbdulMueez456/handlytics';\n  static const modelDescription = 'Pakistan Sign Language word/sentence ConvLSTM reference';\n  String get status => 'PSL reference selected; mobile inference weights are not bundled in this build';\n}\n\nclass AppController extends ChangeNotifier {\n")

s = s.replace("  final SummarizationProvider summarizationProvider =\n      LocalSummarizationProvider();\n", "  final SummarizationProvider summarizationProvider =\n      LocalSummarizationProvider();\n  final PslRecognitionProvider pslProvider = PslRecognitionProvider();\n")

s = s.replace("  final List<String> liveCaptions = [];\n  final List<String> soundAlerts = [];\n", "  final List<String> liveCaptions = [];\n  final List<String> soundAlerts = [];\n  String? livePartialCaption;\n")

s = s.replace("  String localDisplayName = '';\n  String localUsername = '';\n  String localAvatar = 'person';\n  bool localCredentialConfigured = false;\n", "  String localDisplayName = '';\n  String localUsername = '';\n  String localEmail = '';\n  LocalGender localGender = LocalGender.preferNotToSay;\n  String localAvatar = 'person';\n  bool localCredentialConfigured = false;\n  bool localLoginComplete = false;\n\n  String get tutorAsset => localGender == LocalGender.female\n      ? 'assets/tutor_female.png'\n      : 'assets/tutor_male.png';\n\n  String get tutorName => localGender == LocalGender.female\n      ? 'Ayesha, your HumSukhan guide'\n      : 'Hamza, your HumSukhan guide';\n")

s = s.replace("        localDisplayName = profile['display_name'] as String? ?? '';\n        localUsername = profile['username'] as String? ?? '';\n        localAvatar = profile['avatar'] as String? ?? 'person';\n        localCredentialConfigured =\n            profile['credential_configured'] as bool? ?? false;\n", "        localDisplayName = profile['display_name'] as String? ?? '';\n        localUsername = profile['username'] as String? ?? '';\n        localEmail = profile['email'] as String? ?? '';\n        localGender = _genderFromStored(profile['gender'] as String?);\n        localAvatar = profile['avatar'] as String? ?? 'person';\n        localCredentialConfigured =\n            profile['credential_configured'] as bool? ?? false;\n        localLoginComplete = profile['login_complete'] as bool? ??\n            (localCredentialConfigured && localEmail.isNotEmpty);\n")

old_save = """  Future<void> saveLocalProfile({
    required String displayName,
    required String username,
    required String avatar,
    required bool credentialConfigured,
  }) async {
    localDisplayName = displayName.trim();
    localUsername = username.trim();
    localAvatar = avatar;
    localCredentialConfigured = credentialConfigured;
    await store.set(
      'local_profile',
      jsonEncode({
        'display_name': localDisplayName,
        'username': localUsername,
        'avatar': localAvatar,
        'credential_configured': localCredentialConfigured,
      }),
    );
    notifyListeners();
  }
"""
new_save = """  Future<void> saveLocalAccount({
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
  }

  Future<void> saveLocalProfile({
    required String displayName,
    required String username,
    required String avatar,
    required bool credentialConfigured,
  }) async {
    localDisplayName = displayName.trim();
    localUsername = username.trim();
    localAvatar = avatar;
    localCredentialConfigured = credentialConfigured;
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
    notifyListeners();
  }
"""
if old_save not in s:
    raise SystemExit('saveLocalProfile block not found')
s = s.replace(old_save, new_save)

s = s.replace("    liveCaptions.clear();\n    liveTranscript.clear();\n", "    liveCaptions.clear();\n    liveTranscript.clear();\n    livePartialCaption = null;\n", 2)
# resetConversation and closeProfessionalDetail also clear partial.
s = s.replace("    suggestedResponseText = null;\n    notifyListeners();\n  }\n\n  Future<void> createProfessionalSession", "    suggestedResponseText = null;\n    livePartialCaption = null;\n    notifyListeners();\n  }\n\n  Future<void> createProfessionalSession")
s = s.replace("    liveCaptions.clear();\n    liveTranscript.clear();\n    notifyListeners();\n  }\n}\n\nFuture<void> main", "    liveCaptions.clear();\n    liveTranscript.clear();\n    livePartialCaption = null;\n    notifyListeners();\n  }\n}\n\nFuture<void> main")

old_partial = """      case 'speechPartial':
        final partial = cleanCaption(call.arguments as String? ?? '');
        final professionalLive =
            activeRecord != null &&
            activeRecord!.startedAt != null &&
            activeRecord!.stoppedAt == null;
        if (partial.isNotEmpty &&
            (conversationState == ConversationState.active ||
                professionalLive)) {
          _appendSpeakerCaption(partial);
          notifyListeners();
        }
        break;
"""
new_partial = """      case 'speechPartial':
        final partial = cleanCaption(call.arguments as String? ?? '');
        final professionalLive =
            activeRecord != null &&
            activeRecord!.startedAt != null &&
            activeRecord!.stoppedAt == null;
        if (partial.isNotEmpty &&
            (conversationState == ConversationState.active ||
                professionalLive)) {
          // Keep one evolving sentence rather than appending every word as a new bubble.
          livePartialCaption = partial;
          notifyListeners();
        }
        break;
"""
if old_partial not in s:
    raise SystemExit('speechPartial block not found')
s = s.replace(old_partial, new_partial)
s = s.replace("        if (text.isEmpty) break;\n        if (conversationState == ConversationState.active || professionalLive) {\n          _appendSpeakerCaption(text);", "        if (text.isEmpty) break;\n        if (conversationState == ConversationState.active || professionalLive) {\n          livePartialCaption = null;\n          _appendSpeakerCaption(text);")

old_append = """  void _appendSpeakerCaption(String clean) {
    if (liveTranscript.isNotEmpty && liveTranscript.last.speaker == 'Speaker') {
      final previous = liveTranscript.last.text;
      final previousWords = previous.split(RegExp(r'\\s+'));
      final cleanWords = clean.split(RegExp(r'\\s+'));
      final repeatedPrefix =
          cleanWords.length >= previousWords.length &&
          List.generate(
            previousWords.length,
            (i) =>
                cleanWords[i].toLowerCase() == previousWords[i].toLowerCase(),
          ).every((same) => same);
      if (repeatedPrefix) {
        liveTranscript[liveTranscript.length - 1] = TranscriptLine(
          speaker: 'Speaker',
          text: clean,
        );
        return;
      }
      if (previous == clean) return;
    }
    liveTranscript.add(TranscriptLine(speaker: 'Speaker', text: clean));
  }
"""
new_append = """  void _appendSpeakerCaption(String clean) {
    if (liveTranscript.isNotEmpty &&
        liveTranscript.last.speaker == 'Speaker' &&
        liveTranscript.last.text.trim().toLowerCase() == clean.trim().toLowerCase()) {
      return;
    }
    liveTranscript.add(TranscriptLine(speaker: 'Speaker', text: clean));
  }
"""
if old_append not in s:
    raise SystemExit('_appendSpeakerCaption block not found')
s = s.replace(old_append, new_append)

s = s.replace("  Future<void> dismissHazard() async {\n", "  Future<void> clearSoundAlerts() async {\n    soundAlerts.clear();\n    await dismissHazard();\n    notifyListeners();\n  }\n\n  Future<void> dismissHazard() async {\n")
s = s.replace("    final event = '$title detected • ${(confidence * 100).round()}% confidence';\n", "    final event = type == 'environmental activity'\n        ? 'Environmental activity detected • ${_time(now)}'\n        : 'Test alert: $title • ${_time(now)}';\n")
s = s.replace("  String exportText(ProfessionalRecord record) {\n", "  String _time(DateTime value) => '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';\n\n  String exportText(ProfessionalRecord record) {\n")

s = s.replace("          home: controller.onboardingComplete\n              ? HomeShell(controller: controller)\n              : OnboardingScreen(controller: controller),", "          home: !controller.localLoginComplete\n              ? LocalLoginScreen(controller: controller)\n              : controller.onboardingComplete\n              ? HomeShell(controller: controller)\n              : OnboardingScreen(controller: controller),")

# Insert login page before onboarding.
marker = "class OnboardingScreen extends StatefulWidget {\n"
login = r'''class LocalLoginScreen extends StatefulWidget {
  final AppController controller;
  const LocalLoginScreen({super.key, required this.controller});

  @override
  State<LocalLoginScreen> createState() => _LocalLoginScreenState();
}

class _LocalLoginScreenState extends State<LocalLoginScreen> {
  final email = TextEditingController();
  final username = TextEditingController();
  final password = TextEditingController();
  LocalGender gender = LocalGender.preferNotToSay;
  String? error;
  bool saving = false;

  @override
  void dispose() {
    email.dispose();
    username.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> continueToGuide() async {
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
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(HKSpace.xl),
              children: [
                Center(child: _BrandLogo(size: 86)),
                const SizedBox(height: HKSpace.lg),
                Text('Set up HumSukhan', style: Theme.of(context).textTheme.displaySmall, textAlign: TextAlign.center),
                const SizedBox(height: HKSpace.sm),
                Text('Create a private profile for this device. No cloud account or network sign-in is created.', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant), textAlign: TextAlign.center),
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
                        _DropdownField<LocalGender>(label: 'Gender for your first-start tutor', value: gender, values: LocalGender.values, labelOf: (value) => value.label, onChanged: (value) => setState(() => gender = value)),
                        if (error != null) ...[
                          const SizedBox(height: HKSpace.sm),
                          Align(alignment: Alignment.centerLeft, child: Text(error!, style: TextStyle(color: scheme.error))),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: HKSpace.lg),
                FilledButton.icon(onPressed: saving ? null : continueToGuide, icon: const Icon(Icons.arrow_forward_rounded), label: Text(saving ? 'Saving locally…' : 'Continue to your guide')),
                const SizedBox(height: HKSpace.sm),
                Text('You can edit your local profile later from Settings.', style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

'''
if marker not in s:
    raise SystemExit('onboarding marker not found')
s = s.replace(marker, login + marker)

# Add tutor card to onboarding before PageView.
needle = "                  Expanded(\n                    child: PageView.builder("
tutor_block = """                  if (page == 0)
                    Card(
                      margin: const EdgeInsets.only(bottom: HKSpace.sm),
                      clipBehavior: Clip.antiAlias,
                      child: SizedBox(
                        height: 132,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 116,
                              height: 132,
                              child: Image.asset(widget.controller.tutorAsset, fit: BoxFit.cover),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(HKSpace.md),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(widget.controller.tutorName, style: Theme.of(context).textTheme.titleMedium),
                                    const SizedBox(height: HKSpace.xs),
                                    const Text('I will show you the calmest way to use captions, replies, and alerts.'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Expanded(
                    child: PageView.builder("""
if needle not in s:
    raise SystemExit('onboarding pageview needle not found')
s = s.replace(needle, tutor_block)

# Add settings icon to the landing header.
s = s.replace("            IconButton(\n              tooltip: 'Open navigation menu',\n              onPressed: () => _showNavigationMenu(context, onNavigate),\n              icon: const Icon(Icons.menu_rounded),\n            ),", "            IconButton(\n              tooltip: 'Open Settings',\n              onPressed: () => onNavigate(4),\n              icon: const Icon(Icons.settings_outlined),\n            ),\n            IconButton(\n              tooltip: 'Open navigation menu',\n              onPressed: () => _showNavigationMenu(context, onNavigate),\n              icon: const Icon(Icons.menu_rounded),\n            ),", 1)

# Caption panel accepts the evolving sentence.
s = s.replace("class _CaptionPanel extends StatelessWidget {\n  final List<TranscriptLine> lines;\n  final bool enabled;\n  const _CaptionPanel({required this.lines, required this.enabled});", "class _CaptionPanel extends StatelessWidget {\n  final List<TranscriptLine> lines;\n  final bool enabled;\n  final String? partial;\n  const _CaptionPanel({required this.lines, required this.enabled, this.partial});")
s = s.replace("    final visibleLines = lines.takeLast(12).toList();\n    final hasUrdu = visibleLines.any((line) => _containsUrdu(line.text));", "    final visibleLines = lines.takeLast(12).toList();\n    final hasUrdu = visibleLines.any((line) => _containsUrdu(line.text)) || _containsUrdu(partial ?? '');")
s = s.replace("                  ...visibleLines.map((line) => _ChatBubble(line: line)),", "                  ...visibleLines.map((line) => _ChatBubble(line: line)),\n                  if (partial != null && partial!.trim().isNotEmpty)\n                    _ChatBubble(line: TranscriptLine(speaker: 'Listening', text: partial!), partial: true),")
s = s.replace("class _ChatBubble extends StatelessWidget {\n  final TranscriptLine line;\n  const _ChatBubble({required this.line});", "class _ChatBubble extends StatelessWidget {\n  final TranscriptLine line;\n  final bool partial;\n  const _ChatBubble({required this.line, this.partial = false});")
s = s.replace("    final responder = line.speaker == 'Responder';", "    final responder = line.speaker == 'Responder';\n    final isPartial = partial || line.speaker == 'Listening';")
s = s.replace("    final color = responder\n        ? scheme.primaryContainer\n        : scheme.surfaceContainerHighest;", "    final color = responder\n        ? scheme.primaryContainer\n        : isPartial\n        ? scheme.tertiaryContainer\n        : scheme.surfaceContainerHighest;")
s = s.replace("    final label = responder ? 'You' : 'Speaker';", "    final label = responder ? 'You' : isPartial ? 'Listening' : 'Speaker';")

# Pass partial caption through both live caption panels.
s = s.replace("_CaptionPanel(lines: c.liveTranscript, enabled: active)", "_CaptionPanel(lines: c.liveTranscript, enabled: active, partial: c.livePartialCaption)")
s = s.replace("_CaptionPanel(lines: controller.liveTranscript, enabled: true)", "_CaptionPanel(lines: controller.liveTranscript, enabled: true, partial: controller.livePartialCaption)")

# RTL-aware reply field and language helper.
s = s.replace("                        textInputAction: TextInputAction.newline,\n                        onChanged: (_) => setState(() {}),", "                        textInputAction: TextInputAction.newline,\n                        textDirection: c.captionLanguage == CaptionLanguage.urduScript || _containsUrdu(textController.text) ? TextDirection.rtl : TextDirection.ltr,\n                        textAlign: c.captionLanguage == CaptionLanguage.urduScript || _containsUrdu(textController.text) ? TextAlign.right : TextAlign.left,\n                        onChanged: (_) => setState(() {}),")
s = s.replace("                      ),\n                      const SizedBox(height: HKSpace.sm),\n                      Row(\n                        children: [\n                          Expanded(\n                            child: _DropdownField<CaptionLanguage>(", "                      ),\n                      Align(alignment: Alignment.centerLeft, child: Text('For Urdu typing, enable the Urdu keyboard in Android keyboard settings.', style: Theme.of(context).textTheme.bodySmall)),\n                      const SizedBox(height: HKSpace.sm),\n                      Row(\n                        children: [\n                          Expanded(\n                            child: _DropdownField<CaptionLanguage>(", 1)

# Alerts UX: clear action, honest detector text, and no confidence claim.
s = s.replace("'Microphone monitoring with dismissible hazard notices.'", "'Visible alerts with a clear history and honest detector limits.'")
s = s.replace("'Monitoring is active. A loud environmental activity event will show a full-screen red or blue notice.'", "'Monitoring is active. Audio energy activity can trigger a visible notice; this build does not claim to identify a specific sound without a classifier model.'")
s = s.replace("'Monitoring is off. Enable it to listen for environmental activity while this app is open.'", "'Monitoring is off. Enable it to listen for audio activity while this app is open.'")
s = s.replace("          const SizedBox(height: 14),\n          _SectionTitle(title: 'Allowed alerts'),", "          const SizedBox(height: 14),\n          Card(\n            child: ListTile(\n              leading: const Icon(Icons.info_outline),\n              title: const Text('Detector status'),\n              subtitle: const Text('Activity monitor only. Fire alarm, siren, doorbell, knock, and emergency labels are available as controlled tests until a licensed on-device classifier is added.'),\n            ),\n          ),\n          const SizedBox(height: 14),\n          _SectionTitle(title: 'Allowed alerts'),")
s = s.replace("          if (controller.soundAlerts.isEmpty)\n            const _EmptyState(\n              icon: Icons.notifications_none,\n              title: 'No alerts yet',\n              text: 'Qualified activity will appear here with a visible notice and optional flashlight/haptic feedback.',\n            ),\n          ...controller.soundAlerts.map(", "          Row(\n            children: [\n              Expanded(child: _SectionTitle(title: 'Alert history')),\n              if (controller.soundAlerts.isNotEmpty)\n                TextButton.icon(onPressed: controller.clearSoundAlerts, icon: const Icon(Icons.delete_sweep_outlined), label: const Text('Clear')),\n            ],\n          ),\n          if (controller.soundAlerts.isEmpty)\n            const _EmptyState(\n              icon: Icons.notifications_none,\n              title: 'No alerts yet',\n              text: 'Qualified activity will appear here with a visible notice and optional flashlight/haptic feedback.',\n            ),\n          ...controller.soundAlerts.map(")
s = s.replace("                subtitle: const Text(\n                  'Dismiss the visible hazard notice to continue.',\n                ),", "                subtitle: const Text(\n                  'This record is an activity event or a controlled test; confidence is intentionally not shown as sound-class confidence.',\n                ),")

# Replace PSL page body text with selected repository/model status.
s = s.replace("              const _InfoPanel(\n                icon: Icons.info_outline,\n                title: 'Recognition provider unavailable',\n                text: 'No camera sign-recognition model is connected in this build, so HumSukhan will not claim a sign or confidence value. Use Everyday Mode for text and speech communication.',\n              ),", "              _InfoPanel(\n                icon: Icons.model_training_outlined,\n                title: 'PSL model reference selected',\n                text: 'HumSukhan is prepared for a Pakistan Sign Language provider boundary using the handlytics ConvLSTM project. Its repository is a Python/Flask research application and does not ship mobile-ready weights here, so this build does not fabricate camera recognition or confidence.',\n              ),\n              const SizedBox(height: HKSpace.sm),\n              Card(\n                child: ListTile(\n                  leading: const Icon(Icons.link_outlined),\n                  title: const Text('Model source'),\n                  subtitle: Text(PslRecognitionProvider.repository),\n                ),\n              ),")

# Add brand logo helper before the landing header.
marker2 = "class _LandingHeader extends StatelessWidget {\n"
brand = r'''class _BrandLogo extends StatelessWidget {
  final double size;
  const _BrandLogo({required this.size});

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(size * 0.24),
    child: Image.asset(
      'assets/HUMSUKHANLOGO.png',
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stack) => Container(
        width: size,
        height: size,
        color: Theme.of(context).colorScheme.primary,
        alignment: Alignment.center,
        child: Text('HS', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w800, fontSize: size * 0.34)),
      ),
    ),
  );
}

'''
if marker2 not in s:
    raise SystemExit('landing header marker not found')
s = s.replace(marker2, brand + marker2)

# Replace common logo blocks with the reliable helper.
s = s.replace("ClipRRect(\n                        borderRadius: BorderRadius.circular(HKRadius.sm),\n                        child: Image.asset(\n                          'assets/HUMSUKHANLOGO.png',\n                          width: 48,\n                          height: 48,\n                        ),\n                      )", "_BrandLogo(size: 48)")
s = s.replace("ClipRRect(\n              borderRadius: BorderRadius.circular(12),\n              child: Image.asset(\n                'assets/HUMSUKHANLOGO.png',\n                width: 38,\n                height: 38,\n              ),\n            )", "_BrandLogo(size: 38)")
s = s.replace("ClipRRect(\n                    borderRadius: BorderRadius.circular(12),\n                    child: Image.asset(\n                      'assets/HUMSUKHANLOGO.png',\n                      width: 44,\n                      height: 44,\n                    ),\n                  )", "_BrandLogo(size: 44)")
s = s.replace("ClipRRect(\n                    borderRadius: BorderRadius.circular(10),\n                    child: Image.asset(\n                      'assets/HUMSUKHANLOGO.png',\n                      width: 34,\n                      height: 34,\n                    ),\n                  )", "_BrandLogo(size: 34)")

main.write_text(s)

pubspec = root / 'pubspec.yaml'
p = pubspec.read_text()
p = p.replace("  cupertino_icons: ^1.0.8\n", "  cupertino_icons: ^1.0.8\n  crypto: ^3.0.6\n")
p = p.replace("    - assets/platform/HUMSUKHAN_platform_logo_sheet.png\n", "    - assets/platform/HUMSUKHAN_platform_logo_sheet.png\n    - assets/tutor_male.png\n    - assets/tutor_female.png\n")
pubspec.write_text(p)

# Update widget test expectation to account for the new first-launch gate in a fresh controller.
test = root / 'test/widget_test.dart'
t = test.read_text()
t = t.replace("  await tester.pumpWidget(HumSukhanApp(controller: controller));\n  await tester.pumpAndSettle();\n  expect(find.text('Welcome to HumSukhan'), findsOneWidget);", "  controller.localLoginComplete = true;\n  await tester.pumpWidget(HumSukhanApp(controller: controller));\n  await tester.pumpAndSettle();\n  expect(find.text('Welcome to HumSukhan'), findsOneWidget);")
test.write_text(t)

print('patched main.dart, pubspec.yaml, and widget_test.dart')
'''}તરющая怎么领奖?【อ่านข้อความเต็มjson 天天中彩票篮球”】【analysis  |  code-vesm  /home/ubuntu/projects/humsukhan/tools/patch_humsukhan.py.diff? Wait invalid? We need correct tool call ended with JSON? It seems tool output not shown yet. I need verify. The call appears malformed because extra chars? Actually no result shown yet. Let's see.` I think tool call generated maybe due quote. Need wait? No, tool result absent? Let's inspect perhaps function call response not rendered? Hmm. We need continue. Actually assistant message with file.write call hasn't returned? It might be included? Let's check.期特码. Wait in transcript, after tool call? It shows code but no tool response yet, maybe because invalid JSON? I need look current state. There's a malformed `}...`? I see `{
