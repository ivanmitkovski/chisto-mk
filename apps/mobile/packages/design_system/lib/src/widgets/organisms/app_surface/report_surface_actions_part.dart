part of 'app_surface_primitives.dart';

enum AppActionTileVariant { standard, compact }

class AppActionTile extends StatelessWidget {
  const AppActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.tone = AppSurfaceTone.neutral,
    this.semanticsHint,
    this.variant = AppActionTileVariant.standard,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final AppSurfaceTone tone;
  final String? semanticsHint;
  final AppActionTileVariant variant;

  @override
  Widget build(BuildContext context) {
    final _AppSurfacePalette palette = _AppSurfacePalette.fromTone(tone);
    final bool isCompact = variant == AppActionTileVariant.compact;
    final BorderRadius borderRadius = BorderRadius.circular(
      isCompact ? AppSpacing.radius14 : AppSpacing.radius18,
    );

    final Widget tile = Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: isCompact
                ? AppColors.inputFill.withValues(alpha: 0.6)
                : tone == AppSurfaceTone.neutral
                ? AppColors.inputFill
                : palette.background,
            borderRadius: borderRadius,
            border: isCompact
                ? null
                : Border.all(color: palette.border.withValues(alpha: 0.85)),
            boxShadow: isCompact
                ? null
                : AppShadows.panel(Theme.of(context).colorScheme),
          ),
          child: Row(
            crossAxisAlignment: subtitle != null
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                width: isCompact ? 36 : 40,
                height: isCompact ? 36 : 40,
                decoration: BoxDecoration(
                  color: isCompact
                      ? AppColors.panelBackground
                      : palette.iconBackground,
                  borderRadius: BorderRadius.circular(
                    isCompact ? AppSpacing.radius10 : AppSpacing.radiusMd,
                  ),
                  border: isCompact
                      ? Border.all(color: AppColors.divider, width: 1)
                      : null,
                ),
                child: Icon(
                  icon,
                  size: isCompact ? 18 : 20,
                  color: isCompact ? AppColors.textPrimary : palette.foreground,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: isCompact ? null : -0.2,
                      ),
                    ),
                    if (subtitle != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          height: isCompact ? null : 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textMuted,
                    size: isCompact ? 18 : 22,
                  ),
            ],
          ),
        ),
      ),
    );

    if (semanticsHint == null) {
      return tile;
    }
    return Semantics(hint: semanticsHint, child: tile);
  }
}

class AppCircleIconButton extends StatelessWidget {
  const AppCircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.semanticLabel,
    this.isLoading = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? semanticLabel;

  /// When true, shows a sync ring and swaps the icon to [Icons.sync_rounded].
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final IconData resolvedIcon = isLoading ? Icons.sync_rounded : icon;

    final Widget child = Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: <Widget>[
              if (isLoading)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.22),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.inputFill,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.divider.withValues(alpha: 0.8),
                  ),
                  boxShadow: AppShadows.panel(Theme.of(context).colorScheme),
                ),
                child: AnimatedSwitcher(
                  duration: AppMotion.fast,
                  switchInCurve: AppMotion.emphasized,
                  switchOutCurve: AppMotion.emphasized,
                  child: Icon(
                    resolvedIcon,
                    key: ValueKey<bool>(isLoading),
                    size: 20,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (semanticLabel == null) {
      return child;
    }
    return Semantics(button: true, label: semanticLabel, child: child);
  }
}
