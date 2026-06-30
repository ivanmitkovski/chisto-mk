part of 'app_surface_primitives.dart';

class AppStatePill extends StatelessWidget {
  const AppStatePill({
    super.key,
    required this.label,
    this.tone = AppSurfaceTone.neutral,
    this.icon,
    this.emphasized = false,

    /// Tighter padding and icon for dense toolbars (e.g. reports list metrics strip).
    this.dense = false,
  });

  final String label;
  final AppSurfaceTone tone;
  final IconData? icon;
  final bool emphasized;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final _AppSurfacePalette palette = _AppSurfacePalette.fromTone(
      tone,
      emphasized: emphasized,
    );

    return AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.emphasized,
      padding: EdgeInsets.symmetric(
        horizontal: dense ? AppSpacing.xs + 2 : AppSpacing.sm,
        vertical: dense ? 3 : AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusCircle),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: dense ? 12 : 13, color: palette.foreground),
            SizedBox(width: dense ? AppSpacing.xxs : AppSpacing.xs),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.badgeLabel(
              textTheme,
            ).copyWith(color: palette.foreground),
          ),
        ],
      ),
    );
  }
}

class AppBanner extends StatelessWidget {
  const AppBanner({
    super.key,
    required this.message,
    this.title,
    this.icon = Icons.info_outline_rounded,
    this.tone = AppSurfaceTone.neutral,
    this.emphasis = AppBannerEmphasis.primary,
    this.titleStyle,
    this.messageStyle,
  });

  final String? title;
  final String message;
  final IconData icon;
  final AppSurfaceTone tone;

  /// Primary: title scans as a heading. Secondary: supporting label (e.g. credits line).
  final AppBannerEmphasis emphasis;

  /// When set, overrides the default title typography from [emphasis].
  final TextStyle? titleStyle;

  /// When set, overrides the default body typography.
  final TextStyle? messageStyle;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final _AppSurfacePalette palette = _AppSurfacePalette.fromTone(tone);

    final TextStyle? resolvedTitleStyle =
        titleStyle ??
        (title == null
            ? null
            : emphasis == AppBannerEmphasis.primary
            ? AppTypography.cardTitle(textTheme)
            : AppTypography.cardSubtitle(textTheme).copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: -0.1,
              ));

    final TextStyle resolvedMessageStyle =
        messageStyle ??
        (Theme.of(context).textTheme.bodySmall ??
                AppTypography.textTheme.bodySmall!)
            .copyWith(
              color: AppColors.textSecondary,
              height: 1.35,
              fontWeight: emphasis == AppBannerEmphasis.primary
                  ? FontWeight.w500
                  : FontWeight.w400,
            );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: palette.border.withValues(alpha: 0.9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: palette.iconBackground,
              borderRadius: BorderRadius.circular(AppSpacing.radius10),
            ),
            child: Icon(icon, size: 17, color: palette.foreground),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (title != null && resolvedTitleStyle != null) ...<Widget>[
                  Text(title!, style: resolvedTitleStyle),
                  const SizedBox(height: AppSpacing.xxs),
                ],
                Text(message, style: resolvedMessageStyle),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
