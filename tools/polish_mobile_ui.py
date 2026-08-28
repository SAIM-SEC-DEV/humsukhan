from pathlib import Path

p = Path('/home/ubuntu/projects/humsukhan/lib/main.dart')
s = p.read_text()

# Add reusable surface depth helper near the design tokens.
marker = "class HKColors {\n"
helper = """BoxShadow _softSurfaceShadow(ColorScheme scheme) => BoxShadow(
  color: scheme.primary.withValues(alpha: 0.08),
  blurRadius: 24,
  offset: const Offset(0, 10),
);

BoxShadow _tightSurfaceShadow(ColorScheme scheme) => BoxShadow(
  color: scheme.primary.withValues(alpha: 0.06),
  blurRadius: 12,
  offset: const Offset(0, 4),
);

"""
if helper not in s:
    s = s.replace(marker, helper + marker)

# Give Material surfaces a restrained, premium depth system.
s = s.replace("""          cardTheme: CardThemeData(
            margin: EdgeInsets.zero,
            color: scheme.surfaceContainerLow,
            elevation: 0,
            shape: RoundedRectangleBorder(
""", """          cardTheme: CardThemeData(
            margin: EdgeInsets.zero,
            color: scheme.surfaceContainerLow,
            elevation: 1,
            shadowColor: scheme.primary.withValues(alpha: 0.08),
            surfaceTintColor: scheme.surfaceContainerLow,
            shape: RoundedRectangleBorder(
""")
s = s.replace("""          navigationBarTheme: NavigationBarThemeData(
            height: 72,
            backgroundColor: scheme.surfaceContainerLow,
            indicatorColor: scheme.secondaryContainer,
          ),
""", """          navigationBarTheme: NavigationBarThemeData(
            height: 72,
            backgroundColor: scheme.surfaceContainerLow,
            indicatorColor: scheme.secondaryContainer,
            labelTextStyle: WidgetStatePropertyAll(
              TextStyle(fontFamily: 'Atkinson Hyperlegible', fontWeight: FontWeight.w700),
            ),
          ),
          iconButtonTheme: IconButtonThemeData(
            style: IconButton.styleFrom(
              minimumSize: const Size(44, 44),
              shape: const CircleBorder(),
            ),
          ),
          chipTheme: ChipThemeData(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            side: BorderSide(color: scheme.outlineVariant),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
""")

# Modernize the home hero from a flat gradient block to a layered, tactile surface.
s = s.replace("""                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [scheme.primary, scheme.secondary],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(HKRadius.xl),
                      ),
""", """                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            scheme.primary,
                            Color.lerp(scheme.primary, scheme.secondary, 0.62)!,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(HKRadius.xl),
                        boxShadow: [_softSurfaceShadow(scheme)],
                      ),
""", 1)
# Add an understated status pill to the hero before its main row.
s = s.replace("""                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
""", """                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: scheme.onPrimary.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(color: scheme.onPrimary.withValues(alpha: 0.22)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.lock_outline, size: 15, color: scheme.onPrimary),
                                const SizedBox(width: 6),
                                Text('PRIVATE BY DEFAULT', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: scheme.onPrimary, letterSpacing: 0.6)),
                              ],
                            ),
                          ),
                          const SizedBox(height: HKSpace.md),
                          Row(
""", 1)

# Make the home feature tiles read as real mobile navigation cards.
old_tile = """    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HKRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(HKSpace.md),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(HKRadius.md),
                ),
                child: Icon(icon, color: scheme.onPrimaryContainer),
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
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
"""
new_tile = """    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(HKRadius.lg),
        child: Padding(
          padding: const EdgeInsets.all(HKSpace.md),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                  border: Border.all(color: scheme.primary.withValues(alpha: 0.12)),
                ),
                child: Icon(icon, color: scheme.onPrimaryContainer),
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
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
"""
if old_tile not in s:
    raise SystemExit('home tile block not found')
s = s.replace(old_tile, new_tile)

# Add depth and cleaner chrome to the shared page header.
s = s.replace("""              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    scheme.primary.withValues(alpha: 0.18),
                    scheme.tertiary.withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(HKRadius.xl),
              ),
""", """              decoration: BoxDecoration(
                color: scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(HKRadius.xl),
                border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.8)),
                boxShadow: [_tightSurfaceShadow(scheme)],
              ),
""")
s = s.replace("""                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
""", """                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                        ),
""", 1)

# Make caption panels feel like a focused conversation surface.
s = s.replace("""      child: Card(
        color: scheme.surfaceContainerLow,
        child: Padding(
""", """      child: Card(
        clipBehavior: Clip.antiAlias,
        color: scheme.surfaceContainerLow,
        child: Padding(
""", 1)
s = s.replace("""                Divider(color: scheme.outlineVariant),
                const SizedBox(height: HKSpace.sm),
""", """                Divider(color: scheme.outlineVariant.withValues(alpha: 0.72), height: 1),
                const SizedBox(height: HKSpace.md),
""", 1)

# Give live caption bubbles a more physical, app-like depth and softer borders.
s = s.replace("""          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Semantics(
""", """          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: responder ? 0.08 : 0.035),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Semantics(
""", 1)

p.write_text(s)
print('polished mobile visual system')
"
