from pathlib import Path

root = Path('/home/ubuntu/projects/humsukhan')
main = root / 'lib/main.dart'
s = main.read_text()

# Replace the single undifferentiated tool grid with a stronger start-here hierarchy.
old = """                    _SectionTitle(title: 'Your tools'),
                    const SizedBox(height: HKSpace.sm),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 560 ? 2 : 1;
                        return GridView.count(
                          crossAxisCount: columns,
                          mainAxisSpacing: HKSpace.sm,
                          crossAxisSpacing: HKSpace.sm,
                          childAspectRatio: columns == 2 ? 2.25 : 3.5,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _HomeFeatureTile(
                              icon: Icons.forum_outlined,
                              title: 'Everyday Mode',
                              text: 'Live captions and spoken replies',
                              onTap: () => onNavigate(1),
                            ),
                            _HomeFeatureTile(
                              icon: Icons.work_outline,
                              title: 'Professional',
                              text: 'Organized saved sessions',
                              onTap: () => onNavigate(2),
                            ),
                            _HomeFeatureTile(
                              icon: Icons.notifications_none,
                              title: 'Sound Alerts',
                              text: 'Visible environmental notices',
                              onTap: () => onNavigate(3),
                            ),
                            _HomeFeatureTile(
                              icon: Icons.history,
                              title: 'History',
                              text: 'Review saved transcripts',
                              onTap: () => onNavigate(5),
                            ),
                            _HomeFeatureTile(
                              icon: Icons.sign_language,
                              title: 'Sign language',
                              text: 'PSL workspace status',
                              onTap: () => onNavigate(6),
                            ),
                            _HomeFeatureTile(
                              icon: Icons.settings_outlined,
                              title: 'Settings',
                              text: 'Language, privacy, and profile',
                              onTap: () => onNavigate(4),
                            ),
                          ],
                        );
                      },
                    ),
"""
new = """                    _SectionTitle(title: 'Start here'),
                    const SizedBox(height: HKSpace.sm),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 560 ? 2 : 1;
                        return GridView.count(
                          crossAxisCount: columns,
                          mainAxisSpacing: HKSpace.sm,
                          crossAxisSpacing: HKSpace.sm,
                          childAspectRatio: columns == 2 ? 2.25 : 3.5,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _HomeFeatureTile(
                              icon: Icons.forum_outlined,
                              title: 'Everyday Mode',
                              text: 'Live captions and spoken replies',
                              onTap: () => onNavigate(1),
                              emphasis: true,
                            ),
                            _HomeFeatureTile(
                              icon: Icons.work_outline,
                              title: 'Professional',
                              text: 'Organized saved sessions',
                              onTap: () => onNavigate(2),
                              emphasis: true,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: HKSpace.xxl),
                    _SectionTitle(title: 'Support tools'),
                    const SizedBox(height: HKSpace.sm),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final columns = constraints.maxWidth >= 560 ? 2 : 1;
                        return GridView.count(
                          crossAxisCount: columns,
                          mainAxisSpacing: HKSpace.sm,
                          crossAxisSpacing: HKSpace.sm,
                          childAspectRatio: columns == 2 ? 2.25 : 3.5,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            _HomeFeatureTile(
                              icon: Icons.notifications_none,
                              title: 'Sound Alerts',
                              text: 'Visible environmental notices',
                              onTap: () => onNavigate(3),
                            ),
                            _HomeFeatureTile(
                              icon: Icons.history,
                              title: 'History',
                              text: 'Review saved transcripts',
                              onTap: () => onNavigate(5),
                            ),
                            _HomeFeatureTile(
                              icon: Icons.sign_language,
                              title: 'Sign language',
                              text: 'PSL workspace status',
                              onTap: () => onNavigate(6),
                            ),
                            _HomeFeatureTile(
                              icon: Icons.settings_outlined,
                              title: 'Settings',
                              text: 'Language, privacy, and profile',
                              onTap: () => onNavigate(4),
                            ),
                          ],
                        );
                      },
                    ),
"""
if old not in s:
    raise SystemExit('home hierarchy block not found')
s = s.replace(old, new)

# Add emphasis support to feature tiles.
s = s.replace("""  final String text;
  final VoidCallback onTap;
  const _HomeFeatureTile({
    required this.icon,
    required this.title,
    required this.text,
    required this.onTap,
  });
""", """  final String text;
  final VoidCallback onTap;
  final bool emphasis;
  const _HomeFeatureTile({
    required this.icon,
    required this.title,
    required this.text,
    required this.onTap,
    this.emphasis = false,
  });
""")
s = s.replace("""        child: Padding(
          padding: const EdgeInsets.all(HKSpace.md),
          child: Row(
""", """        child: Padding(
          padding: EdgeInsets.all(emphasis ? HKSpace.lg : HKSpace.md),
          child: Row(
""", 1)
s = s.replace("""                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
""", """                  color: emphasis ? scheme.secondaryContainer : scheme.primaryContainer,
                  shape: BoxShape.circle,
""", 1)
s = s.replace("""                child: Icon(icon, color: scheme.onPrimaryContainer),
""", """                child: Icon(icon, color: scheme.onSecondaryContainer),
""", 1)

# Replace the passive active microphone row with an animated, high-salience live cue.
old_active = """                        else
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: HKSpace.md,
                            vertical: HKSpace.sm,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            borderRadius: BorderRadius.circular(HKRadius.md),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                c.microphoneListening
                                    ? Icons.mic
                                    : Icons.mic_off_outlined,
                                color: scheme.onPrimaryContainer,
                              ),
                              const SizedBox(width: HKSpace.sm),
                              Expanded(
                                child: Text(
                                  c.microphoneListening
                                      ? 'Listening for speech'
                                      : 'Microphone is reconnecting',
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(
                                        color: scheme.onPrimaryContainer,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
"""
new_active = """                        else
                          _AttentionCue(
                            active: c.microphoneListening,
                            title: c.microphoneListening
                                ? 'Listening for speech'
                                : 'Reconnecting microphone',
                            subtitle: c.microphoneListening
                                ? 'Speak naturally. Your next sentence will appear below.'
                                : 'Keep this screen open while the speech service reconnects.',
                          ),
"""
if old_active not in s:
    raise SystemExit('everyday active mic block not found')
s = s.replace(old_active, new_active)

# Use the same attention cue in Professional live sessions.
s = s.replace("""                Container(
                  padding: const EdgeInsets.all(HKSpace.md),
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(HKRadius.md),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.mic, color: scheme.onPrimaryContainer),
                      const SizedBox(width: HKSpace.sm),
                      Expanded(
                        child: Text(
                          controller.microphoneListening
                              ? 'Live captions are listening'
                              : 'Microphone is reconnecting',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: scheme.onPrimaryContainer),
                        ),
                      ),
                    ],
                  ),
                ),
""", """                _AttentionCue(
                  active: controller.microphoneListening,
                  title: controller.microphoneListening
                      ? 'Live captions are listening'
                      : 'Reconnecting microphone',
                  subtitle: controller.microphoneListening
                      ? 'Speak naturally. Complete sentences will appear in the transcript.'
                      : 'The speech service is restarting its listening window.',
                ),
""")

# Insert animated attention cue before the chat bubble implementation.
marker = "class _ChatBubble extends StatelessWidget {\n"
attention = """class _AttentionCue extends StatefulWidget {
  final bool active;
  final String title;
  final String subtitle;
  const _AttentionCue({
    required this.active,
    required this.title,
    required this.subtitle,
  });

  @override
  State<_AttentionCue> createState() => _AttentionCueState();
}

class _AttentionCueState extends State<_AttentionCue>
    with SingleTickerProviderStateMixin {
  late final AnimationController pulse;

  @override
  void initState() {
    super.initState();
    pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.active) pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _AttentionCue oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !pulse.isAnimating) {
      pulse.repeat(reverse: true);
    } else if (!widget.active && pulse.isAnimating) {
      pulse.stop();
    }
  }

  @override
  void dispose() {
    pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = widget.active ? HKColors.live : scheme.tertiary;
    return AnimatedBuilder(
      animation: pulse,
      builder: (context, _) {
        final glow = widget.active ? 0.08 + pulse.value * 0.11 : 0.05;
        return Container(
          padding: const EdgeInsets.all(HKSpace.md),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(HKRadius.md),
            border: Border.all(color: accent.withValues(alpha: 0.34)),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: glow),
                blurRadius: 18,
                spreadRadius: widget.active ? pulse.value * 2 : 0,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.active ? Icons.mic_rounded : Icons.sync_rounded,
                  color: accent,
                ),
              ),
              const SizedBox(width: HKSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: HKSpace.xxs),
                    Text(
                      widget.subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (widget.active)
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: HKColors.live, shape: BoxShape.circle),
                ),
            ],
          ),
        );
      },
    );
  }
}

"""
if attention not in s:
    s = s.replace(marker, attention + marker)

main.write_text(s)

report = root / 'OFFLINE_SPEECH_OPTIONS.md'
report.write_text("""# Offline speech-recognition options for HumSukhan

## Recommendation

The strongest replacement for Android `SpeechRecognizer` is **Sherpa-ONNX**, integrated behind HumSukhan’s existing `SpeechToTextProvider` abstraction. The project supports offline streaming and non-streaming ASR, Android, Dart, Kotlin, VAD, punctuation, and pre-built Flutter examples. The published Flutter package is actively released and currently documents Android support and local inference.[1][2][3]

Sherpa-ONNX is the best fit when HumSukhan needs continuous listening, predictable privacy behavior, and a future path to voice-activity detection and punctuation. It still requires selecting, packaging, and testing a model. The public model catalog is not a guarantee of Urdu coverage; an Urdu or multilingual model must be validated on-device before enabling Urdu claims.

## Alternatives

| Option | Offline | Streaming | Android / Flutter fit | English and Urdu considerations | Recommendation |
|---|---:|---:|---|---|---|
| **Sherpa-ONNX** | Yes | Yes | Strong: official Flutter examples, Android artifacts, Dart/Kotlin/C++ surfaces | English models are available in the catalog; Urdu availability must be confirmed model-by-model | **Preferred production path** |
| **Vosk via `vosk_flutter_service`** | Yes | Yes, through its Android microphone service | Good for a smaller Android-first integration; the package documents bundled Android binaries and asset-loaded models | Model selection is the deciding factor; English is practical, Urdu requires a compatible Vosk model and accuracy testing | **Good lightweight fallback** |
| **Whisper.cpp via `whisper_cpp_flutter_plus` or a maintained binding** | Yes | Usually chunked or application-managed streaming rather than native low-latency streaming | Strong native Android performance potential, but model size, CPU cost, and packaging complexity are higher | Whisper’s multilingual model family includes Urdu capability, but small-device latency and word timing must be tested; model license and redistribution terms must be checked | **Best accuracy-oriented fallback** |
| **`speech_to_text`** | Device-dependent | Device-dependent | Easy Flutter API, but it delegates to the platform recognition service | It does not solve the current reliability/offline dependency by itself | **Not an offline replacement** |

## Integration plan

First, keep Android `SpeechRecognizer` as the current provider and add a selectable `OfflineSpeechProvider` interface. Second, implement Sherpa-ONNX streaming ASR on a feature branch using a small English model and a local audio input path. Third, add a separately validated Urdu or multilingual model only after measuring latency, memory use, partial-result quality, and sentence punctuation on target Android hardware. Fourth, use VAD and punctuation as separate provider capabilities rather than presenting unsupported confidence values. Finally, make the provider visible in Settings so users know whether the app is using Android recognition or a bundled local model.

Do not ship a large model directly into the APK until its size, native ABI coverage, license, startup time, and memory use have been measured. A practical release may use Play Asset Delivery or a first-run local model download, but that would change the current strictly local/offline packaging promise and needs an explicit product decision.

## Sources

[1]: https://github.com/k2-fsa/sherpa-onnx "Sherpa-ONNX repository — offline ASR, streaming support, Android, Dart, and model catalog"
[2]: https://k2-fsa.github.io/sherpa/onnx/flutter/pre-built-app.html "Sherpa-ONNX pre-built Flutter applications and streaming ASR examples"
[3]: https://pub.dev/packages/sherpa_onnx "sherpa_onnx Flutter package metadata and platform support"
[4]: https://pub.dev/packages/vosk_flutter_service "Vosk Flutter Service package documentation and offline Android microphone example"
[5]: https://github.com/ggml-org/whisper.cpp "Whisper.cpp repository — native offline Whisper inference"
[6]: https://pub.dev/packages/whisper_cpp_flutter_plus "Whisper.cpp Flutter package listing"
[7]: https://pub.dev/packages/speech_to_text "speech_to_text package — platform speech recognition wrapper"
""")
print('applied hierarchy polish and wrote offline speech options report')
"
