from pathlib import Path

root = Path('/home/ubuntu/projects/humsukhan')
main = root / 'lib/main.dart'
s = main.read_text()

# Strengthen Home hierarchy by separating primary modes from support tools.
home_start = s.index("                    _SectionTitle(title: 'Your tools'),")
home_end = s.index("                    const SizedBox(height: HKSpace.xxl),\n                    _SectionTitle(title: 'Recent professional sessions'),", home_start)
home_block = '''                    _SectionTitle(title: 'Start here'),
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
'''
s = s[:home_start] + home_block + s[home_end:]

# Add visual emphasis to the two primary Home mode cards.
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
""", 1)
feature_start = s.index('class _HomeFeatureTile extends StatelessWidget {')
feature_build = s.index('  @override\n  Widget build(BuildContext context) {', feature_start)
feature_end = s.index('\n}\n\nclass _RecentRecordTile', feature_build)
feature_method = '''  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HKRadius.lg),
        child: Padding(
          padding: EdgeInsets.all(emphasis ? HKSpace.lg : HKSpace.md),
          child: Row(
            children: [
              Container(
                width: emphasis ? 50 : 46,
                height: emphasis ? 50 : 46,
                decoration: BoxDecoration(
                  color: emphasis ? scheme.secondaryContainer : scheme.primaryContainer,
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.primary.withValues(alpha: 0.12)),
                ),
                child: Icon(icon, color: emphasis ? scheme.onSecondaryContainer : scheme.onPrimaryContainer),
              ),
              const SizedBox(width: HKSpace.sm),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: HKSpace.xxs),
                    Text(
                      text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(color: scheme.surfaceContainerHighest, shape: BoxShape.circle),
                child: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
'''
s = s[:feature_build] + feature_method + s[feature_end:]

# Replace Everyday's passive microphone strip with an animated attention cue.
every = s.index('class EverydayPage extends StatefulWidget')
every_start = s.index('                      else\n                        Container(', every)
every_end = s.index('                        ),\n                    ],', every_start) + len('                        ),\n')
s = s[:every_start] + '''                      else
                        _AttentionCue(
                          active: c.microphoneListening,
                          title: c.microphoneListening ? 'Listening for speech' : 'Reconnecting microphone',
                          subtitle: c.microphoneListening
                              ? 'Speak naturally. Your next sentence will appear below.'
                              : 'Keep this screen open while the speech service reconnects.',
                        ),
''' + s[every_end:]

# Replace Professional's passive microphone strip too.
pro = s.index('class ProfessionalPage extends StatefulWidget')
pro_detail = s.index('class _ProfessionalDetail extends StatelessWidget')
pro_start = s.index('                Container(\n                  padding: const EdgeInsets.all(HKSpace.md),', pro_detail)
pro_end = s.index('                const SizedBox(height: HKSpace.md),', pro_start)
s = s[:pro_start] + '''                _AttentionCue(
                  active: controller.microphoneListening,
                  title: controller.microphoneListening ? 'Live captions are listening' : 'Reconnecting microphone',
                  subtitle: controller.microphoneListening
                      ? 'Speak naturally. Complete sentences will appear in the transcript.'
                      : 'The speech service is restarting its listening window.',
                ),
''' + s[pro_end:]

# Add the reusable animated attention cue before chat bubbles.
marker = 'class _ChatBubble extends StatelessWidget {\n'
if 'class _AttentionCue extends StatefulWidget {' not in s:
    attention = '''class _AttentionCue extends StatefulWidget {
  final bool active;
  final String title;
  final String subtitle;
  const _AttentionCue({required this.active, required this.title, required this.subtitle});

  @override
  State<_AttentionCue> createState() => _AttentionCueState();
}

class _AttentionCueState extends State<_AttentionCue> with SingleTickerProviderStateMixin {
  late final AnimationController pulse;

  @override
  void initState() {
    super.initState();
    pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    if (widget.active) pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _AttentionCue oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !pulse.isAnimating) pulse.repeat(reverse: true);
    if (!widget.active && pulse.isAnimating) pulse.stop();
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
            boxShadow: [BoxShadow(color: accent.withValues(alpha: glow), blurRadius: 18, spreadRadius: widget.active ? pulse.value * 2 : 0)],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: accent.withValues(alpha: 0.16), shape: BoxShape.circle),
                child: Icon(widget.active ? Icons.mic_rounded : Icons.sync_rounded, color: accent),
              ),
              const SizedBox(width: HKSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: HKSpace.xxs),
                    Text(widget.subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
              if (widget.active) Container(width: 10, height: 10, decoration: const BoxDecoration(color: HKColors.live, shape: BoxShape.circle)),
            ],
          ),
        );
      },
    );
  }
}

'''
    s = s.replace(marker, attention + marker, 1)

main.write_text(s)
print('applied hierarchy and attention cue patch')
"
