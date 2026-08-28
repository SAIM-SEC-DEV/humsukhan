from pathlib import Path

root = Path('/home/ubuntu/projects/humsukhan')
main = root / 'lib/main.dart'
s = main.read_text()

# Use the transparent tutor assets for all first-run guide surfaces.
s = s.replace("? 'assets/tutor_female.png'\n      : 'assets/tutor_male.png';", "? 'assets/tutor_female_transparent.png'\n      : 'assets/tutor_male_transparent.png';")

# Remove the separate page-0-only tutor card from the onboarding shell.
start = "                  if (page == 0)\n                    Card(\n"
end = "                  Expanded(\n                    child: PageView.builder("
if start not in s or end not in s:
    raise SystemExit('onboarding tutor card markers not found')
card_start = s.index(start)
card_end = s.index(end, card_start)
s = s[:card_start] + s[card_end:]

# Pass tutor identity into every slide.
s = s.replace(
    "_OnboardingSlideView(slide: slides[index]),",
    "_OnboardingSlideView(\n                            slide: slides[index],\n                            tutorAsset: widget.controller.tutorAsset,\n                            tutorName: widget.controller.tutorName,\n                          ),",
)

# Replace the slide view with a tutor-led, transparent composition on every page.
old_class = """class _OnboardingSlideView extends StatelessWidget {
  final _OnboardingSlide slide;
  const _OnboardingSlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: HKSpace.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [scheme.primary, scheme.secondary],
              ),
              borderRadius: BorderRadius.circular(HKRadius.xl),
            ),
            child: Icon(slide.icon, size: 44, color: scheme.onPrimary),
          ),
          const SizedBox(height: HKSpace.xxl),
          Text(slide.title, style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: HKSpace.md),
          Text(
            slide.text,
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: HKSpace.xl),
                    if (slide.accent)
            const _InfoPanel(
              icon: Icons.lock_outline,
              title: 'Privacy by default',
              text:
                  'Audio is processed temporarily and released. Saved Professional records contain captions and metadata only.',
            ),
          ],
        ),
      ),
    );
  }
}
"""
new_class = """class _OnboardingSlideView extends StatelessWidget {
  final _OnboardingSlide slide;
  final String tutorAsset;
  final String tutorName;
  const _OnboardingSlideView({
    required this.slide,
    required this.tutorAsset,
    required this.tutorName,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: HKSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 168,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(HKSpace.md),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(HKRadius.lg),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tutorName, style: Theme.of(context).textTheme.labelLarge),
                          const SizedBox(height: HKSpace.xs),
                          Text(
                            'I will point out what matters on this screen.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onPrimaryContainer),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 156,
                    height: 168,
                    child: Image.asset(tutorAsset, fit: BoxFit.contain),
                  ),
                ],
              ),
            ),
            const SizedBox(height: HKSpace.lg),
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [scheme.primary, scheme.secondary]),
                borderRadius: BorderRadius.circular(HKRadius.lg),
              ),
              child: Icon(slide.icon, size: 36, color: scheme.onPrimary),
            ),
            const SizedBox(height: HKSpace.lg),
            Text(slide.title, style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: HKSpace.md),
            Text(
              slide.text,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: HKSpace.lg),
            if (slide.accent)
              const _InfoPanel(
                icon: Icons.lock_outline,
                title: 'Privacy by default',
                text: 'Audio is processed temporarily and released. Saved Professional records contain captions and metadata only.',
              ),
          ],
        ),
      ),
    );
  }
}
"""
if old_class not in s:
    raise SystemExit('onboarding slide class not found')
s = s.replace(old_class, new_class)

# Make the live speech state visible and provide a deterministic retry action in the UI.
s = s.replace(
    "                        active\n                            ? (c.microphoneListening\n                                  ? 'Microphone active. Speak naturally.'\n                                  : 'Preparing the microphone…')\n                            : 'Start when you are ready. Nothing listens automatically.',",
    "                        active\n                            ? (c.microphoneListening\n                                  ? 'Microphone active. Speak naturally.'\n                                  : 'Waiting for the speech service…')\n                            : 'Start when you are ready. Nothing listens automatically.',",
)
s = s.replace(
    "                      if (c.nativeError != null) ...[\n                const SizedBox(height: HKSpace.sm),\n                _ErrorPanel(text: c.nativeError!),\n              ],",
    "                      if (c.nativeError != null) ...[\n                const SizedBox(height: HKSpace.sm),\n                _ErrorPanel(text: c.nativeError!),\n                if (active) ...[\n                  const SizedBox(height: HKSpace.xs),\n                  OutlinedButton.icon(\n                    onPressed: c.startNativeSpeech,\n                    icon: const Icon(Icons.refresh_rounded),\n                    label: const Text('Retry speech recognition'),\n                  ),\n                ],\n              ],",
)

# Register the transparent files as assets; keep original assets available for compatibility.
pubspec = root / 'pubspec.yaml'
p = pubspec.read_text()
line = "    - assets/tutor_male_transparent.png\n    - assets/tutor_female_transparent.png\n"
if line not in p:
    p = p.replace("    - assets/tutor_female.png\n", "    - assets/tutor_female.png\n" + line)
pubspec.write_text(p)
main.write_text(s)
print('patched tutor composition and speech retry UI')

# Native bridge patch: do not force offline recognition, recover permission automatically,
# and surface every terminal error instead of silently looping with a false listening state.
kotlin = root / 'android/app/src/main/kotlin/com/humsukhan/humsukhan/MainActivity.kt'
k = kotlin.read_text()
k = k.replace('    private var audioThread: Thread? = null\n', '    private var audioThread: Thread? = null\n    private var pendingSpeechLocale: String? = null\n    private var recognitionErrorCount = 0\n')
k = k.replace('''        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.RECORD_AUDIO), speechPermissionRequest)
            result.error("MIC_PERMISSION_REQUIRED", "Microphone permission is required. Start captions again after granting it.", null)
            return
        }
''', '''        val requestedLocale = call.argument<String>("locale") ?: "en-US"
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            pendingSpeechLocale = requestedLocale
            ActivityCompat.requestPermissions(this, arrayOf(Manifest.permission.RECORD_AUDIO), speechPermissionRequest)
            result.error("MIC_PERMISSION_REQUIRED", "Microphone permission is required. Captions will begin after permission is granted.", null)
            return
        }
        beginSpeech(requestedLocale)
        result.success(null)
    }

    private fun beginSpeech(locale: String) {
''')
k = k.replace('''        speechIntent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            // Partial hypotheses stay internal; Flutter renders only final sentences.
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, call.argument<String>("locale") ?: "en-US")
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 3)
            putExtra(RecognizerIntent.EXTRA_PREFER_OFFLINE, true)
''', '''        speechIntent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, locale)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_PREFERENCE, locale)
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 5)
            // Do not force offline mode: many Android devices have no offline pack,
            // which otherwise produces a silent/no-result recognition failure.
''')
k = k.replace('''        createRecognizerIfNeeded()
        startListeningNow()
        result.success(null)
    }

    private fun createRecognizerIfNeeded() {''', '''        recognitionErrorCount = 0
        createRecognizerIfNeeded()
        startListeningNow()
    }

    private fun createRecognizerIfNeeded() {''')
k = k.replace('''            override fun onResults(results: Bundle?) {
                val text = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)?.firstOrNull()
                if (!text.isNullOrBlank()) invokeFlutter("speechFinal", text)
                restartListeningIfNeeded(220)
            }
            override fun onError(error: Int) {
                if (continuousListening && !userRequestedStop && error != SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS) {
                    // Android ends a recognition window after silence or a result.
                    // Restarting the same recognizer keeps the user-facing session live.
                    restartListeningIfNeeded(if (error == SpeechRecognizer.ERROR_NO_MATCH) 160 else 500)
                } else {
                    invokeFlutter("speechStatus", "stopped")
                    invokeFlutter("speechError", speechErrorMessage(error))
                }
            }
''', '''            override fun onResults(results: Bundle?) {
                val text = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)?.firstOrNull()
                if (!text.isNullOrBlank()) invokeFlutter("speechFinal", text)
                recognitionErrorCount = 0
                restartListeningIfNeeded(260)
            }
            override fun onError(error: Int) {
                if (continuousListening && !userRequestedStop && error != SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS) {
                    recognitionErrorCount += 1
                    invokeFlutter("speechStatus", "reconnecting")
                    invokeFlutter("speechError", speechErrorMessage(error))
                    restartListeningIfNeeded(if (error == SpeechRecognizer.ERROR_NO_MATCH) 240 else 700)
                } else {
                    invokeFlutter("speechStatus", "stopped")
                    invokeFlutter("speechError", speechErrorMessage(error))
                }
            }
''')
k = k.replace('''    private fun startListeningNow() {
        if (!continuousListening || userRequestedStop) return
        try {
            speechRecognizer?.startListening(speechIntent ?: return)
            invokeFlutter("speechStatus", "listening")
        } catch (_: Exception) {
            restartListeningIfNeeded(700)
        }
    }
''', '''    private fun startListeningNow() {
        if (!continuousListening || userRequestedStop) return
        try {
            speechRecognizer?.startListening(speechIntent ?: return)
            invokeFlutter("speechStatus", "listening")
        } catch (error: Exception) {
            invokeFlutter("speechStatus", "reconnecting")
            invokeFlutter("speechError", error.message ?: "Speech recognition could not start.")
            restartListeningIfNeeded(900)
        }
    }
''')
# Add automatic permission recovery before shareTextFile.
marker = '    private fun startSoundMonitoring(result: MethodChannel.Result) {\n'
permission = '''    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == speechPermissionRequest && grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
            pendingSpeechLocale?.let {
                pendingSpeechLocale = null
                beginSpeech(it)
                invokeFlutter("speechStatus", "listening")
            }
        } else if (requestCode == speechPermissionRequest) {
            invokeFlutter("speechStatus", "stopped")
            invokeFlutter("speechError", "Microphone permission was not granted.")
        }
    }

'''
if marker not in k:
    raise SystemExit('native insertion marker not found')
k = k.replace(marker, permission + marker)
kotlin.write_text(k)
print('patched Android speech bridge')
''
