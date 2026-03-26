import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:flutter/material.dart';

enum ReportSurfaceTone { neutral, accent, success, warning, danger }

enum ReportInfoBannerEmphasis { primary, secondary }

TextStyle _reportSheetSubtitleStyle() {
  final TextStyle? base = AppTypography.textTheme.bodySmall;
  return (base ?? AppTypography.cardSubtitle).copyWith(
    color: AppColors.textMuted,
    height: 1.35,
  );
}

ScrollPhysics _reportSheetListPhysics(BuildContext context) {
  return Theme.of(context).platform == TargetPlatform.iOS
      ? const BouncingScrollPhysics()
      : const ClampingScrollPhysics();
}

class ReportSheetScaffold extends StatelessWidget {
  const ReportSheetScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.leading,
    this.trailing,
    this.footer,
    this.maxHeightFactor = 0.9,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.sm,
      AppSpacing.lg,
      AppSpacing.lg,
    ),
    this.showHeaderDivider = true,
    this.addBottomInset = true,
    this.headerDividerGap = AppSpacing.md,
    this.fitToContent = false,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final Widget child;
  final Widget? footer;
  final double maxHeightFactor;
  final EdgeInsets padding;
  final bool showHeaderDivider;
  final bool addBottomInset;
  /// Vertical space above and below the header rule (smaller feels tighter).
  final double headerDividerGap;

  /// Sheet height follows content until [maxHeightFactor] of the screen, then scrolls.
  final bool fitToContent;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData media = MediaQuery.of(context);
    final double topPadding = media.padding.top;
    final double bottomPadding = media.padding.bottom;
    final double heightCap = media.size.height * maxHeightFactor;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double parentMax = constraints.maxHeight;
        final double sheetHeight = parentMax.isFinite
            ? parentMax.clamp(1.0, heightCap)
            : heightCap;

        final BorderRadius sheetRadius = BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusCard),
        );

        if (fitToContent) {
          return DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.panelBackground,
              borderRadius: sheetRadius,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.06),
                  blurRadius: 36,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: sheetRadius,
              clipBehavior: Clip.hardEdge,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: heightCap),
                child: Material(
                  type: MaterialType.transparency,
                  child: ListView(
                    shrinkWrap: true,
                    physics: _reportSheetListPhysics(context),
                    padding: padding,
                    children: <Widget>[
                      const SizedBox(height: AppSpacing.xs),
                      const Center(child: _ReportSheetHandle()),
                      SizedBox(
                        height: topPadding > 0 ? AppSpacing.xs : AppSpacing.radius14,
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          if (leading != null) ...<Widget>[
                            leading!,
                            const SizedBox(width: AppSpacing.sm),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  title,
                                  style: AppTypography.sheetTitle,
                                ),
                                if (subtitle != null) ...<Widget>[
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    subtitle!,
                                    style: _reportSheetSubtitleStyle(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (trailing != null) ...<Widget>[
                            const SizedBox(width: AppSpacing.sm),
                            trailing!,
                          ],
                        ],
                      ),
                      if (showHeaderDivider) ...<Widget>[
                        SizedBox(height: headerDividerGap),
                        Divider(
                          color: AppColors.divider.withValues(alpha: 0.6),
                          height: 1,
                        ),
                        SizedBox(height: headerDividerGap),
                      ] else
                        const SizedBox(height: AppSpacing.sm),
                      ColoredBox(
                        color: AppColors.panelBackground,
                        child: child,
                      ),
                      if (footer != null) ...<Widget>[
                        const SizedBox(height: AppSpacing.lg),
                        footer!,
                      ],
                      if (addBottomInset) SizedBox(height: bottomPadding),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        // DecoratedBox paints the card; hard-edge clip avoids iOS anti-alias seams.
        // Material(type: transparency) supplies a Material ancestor for Text/InkWell
        // (avoids debug yellow underlines) without painting another opaque surface.
        return DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.panelBackground,
            borderRadius: sheetRadius,
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.06),
                blurRadius: 36,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: sheetRadius,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              height: sheetHeight,
              child: Material(
                type: MaterialType.transparency,
                child: SafeArea(
                  top: false,
                  bottom: false,
                  child: Padding(
                    padding: padding,
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const SizedBox(height: AppSpacing.xs),
                        const Center(child: _ReportSheetHandle()),
                        SizedBox(
                          height: topPadding > 0 ? AppSpacing.xs : AppSpacing.radius14,
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            if (leading != null) ...<Widget>[
                              leading!,
                              const SizedBox(width: AppSpacing.sm),
                            ],
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    title,
                                    style: AppTypography.sheetTitle,
                                  ),
                                  if (subtitle != null) ...<Widget>[
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      subtitle!,
                                      style: _reportSheetSubtitleStyle(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (trailing != null) ...<Widget>[
                              const SizedBox(width: AppSpacing.sm),
                              trailing!,
                            ],
                          ],
                        ),
                        if (showHeaderDivider) ...<Widget>[
                          SizedBox(height: headerDividerGap),
                          Divider(
                            color: AppColors.divider.withValues(alpha: 0.6),
                            height: 1,
                          ),
                          SizedBox(height: headerDividerGap),
                        ] else
                          const SizedBox(height: AppSpacing.sm),
                        Expanded(
                          child: ColoredBox(
                            color: AppColors.panelBackground,
                            child: child,
                          ),
                        ),
                        if (footer != null) ...<Widget>[
                          const SizedBox(height: AppSpacing.lg),
                          footer!,
                        ],
                        if (addBottomInset) SizedBox(height: bottomPadding),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class ReportStatePill extends StatelessWidget {
  const ReportStatePill({
    super.key,
    required this.label,
    this.tone = ReportSurfaceTone.neutral,
    this.icon,
    this.emphasized = false,
  });

  final String label;
  final ReportSurfaceTone tone;
  final IconData? icon;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final _ReportSurfacePalette palette = _ReportSurfacePalette.fromTone(
      tone,
      emphasized: emphasized,
    );

    return AnimatedContainer(
      duration: AppMotion.fast,
      curve: AppMotion.emphasized,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
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
            Icon(icon, size: 13, color: palette.foreground),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.badgeLabel.copyWith(
              color: palette.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class ReportInfoBanner extends StatelessWidget {
  const ReportInfoBanner({
    super.key,
    required this.message,
    this.title,
    this.icon = Icons.info_outline_rounded,
    this.tone = ReportSurfaceTone.neutral,
    this.emphasis = ReportInfoBannerEmphasis.primary,
  });

  final String? title;
  final String message;
  final IconData icon;
  final ReportSurfaceTone tone;
  /// Primary: title scans as a heading. Secondary: supporting label (e.g. credits line).
  final ReportInfoBannerEmphasis emphasis;

  @override
  Widget build(BuildContext context) {
    final _ReportSurfacePalette palette = _ReportSurfacePalette.fromTone(tone);

    final TextStyle? titleStyle = title == null
        ? null
        : emphasis == ReportInfoBannerEmphasis.primary
            ? AppTypography.cardTitle
            : AppTypography.cardSubtitle.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: -0.1,
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
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: palette.foreground),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (title != null && titleStyle != null) ...<Widget>[
                  Text(
                    title!,
                    style: titleStyle,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                ],
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.35,
                    fontWeight: emphasis == ReportInfoBannerEmphasis.primary
                        ? FontWeight.w500
                        : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ReportActionTile extends StatelessWidget {
  const ReportActionTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailing,
    this.tone = ReportSurfaceTone.neutral,
    this.semanticsHint,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final ReportSurfaceTone tone;
  final String? semanticsHint;

  @override
  Widget build(BuildContext context) {
    final _ReportSurfacePalette palette = _ReportSurfacePalette.fromTone(tone);

    final Widget tile = Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: tone == ReportSurfaceTone.neutral
                ? AppColors.inputFill
                : palette.background,
            borderRadius: BorderRadius.circular(AppSpacing.radius18),
            border: Border.all(color: palette.border.withValues(alpha: 0.85)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.018),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: subtitle != null
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: palette.iconBackground,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(icon, size: 20, color: palette.foreground),
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
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (subtitle != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          height: 1.35,
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
                    size: 22,
                  ),
            ],
          ),
        ),
      ),
    );

    if (semanticsHint == null) {
      return tile;
    }
    return Semantics(
      hint: semanticsHint,
      child: tile,
    );
  }
}

class ReportCircleIconButton extends StatelessWidget {
  const ReportCircleIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final Widget child = Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.inputFill,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.divider.withValues(alpha: 0.8)),
            boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, size: 20, color: AppColors.textPrimary),
        ),
      ),
    );

    if (semanticLabel == null) {
      return child;
    }
    return Semantics(button: true, label: semanticLabel, child: child);
  }
}

class _ReportSheetHandle extends StatelessWidget {
  const _ReportSheetHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSpacing.sheetHandle,
      height: AppSpacing.sheetHandleHeight,
      decoration: BoxDecoration(
        color: AppColors.divider,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
      ),
    );
  }
}

class _ReportSurfacePalette {
  const _ReportSurfacePalette({
    required this.background,
    required this.foreground,
    required this.border,
    required this.iconBackground,
  });

  final Color background;
  final Color foreground;
  final Color border;
  final Color iconBackground;

  factory _ReportSurfacePalette.fromTone(
    ReportSurfaceTone tone, {
    bool emphasized = false,
  }) {
    switch (tone) {
      case ReportSurfaceTone.accent:
        return _ReportSurfacePalette(
          background: emphasized
              ? AppColors.primaryDark
              : AppColors.primary.withValues(alpha: 0.1),
          foreground: emphasized ? AppColors.white : AppColors.primaryDark,
          border: emphasized
              ? AppColors.primaryDark
              : AppColors.primaryDark.withValues(alpha: 0.18),
          iconBackground: emphasized
              ? AppColors.white.withValues(alpha: 0.16)
              : AppColors.primary.withValues(alpha: 0.16),
        );
      case ReportSurfaceTone.success:
        return const _ReportSurfacePalette(
          background: Color(0xFFEDFFF6),
          foreground: AppColors.primaryDark,
          border: Color(0xFFD0F0DF),
          iconBackground: Color(0xFFDDF7E9),
        );
      case ReportSurfaceTone.warning:
        return const _ReportSurfacePalette(
          background: Color(0xFFFFF6E8),
          foreground: AppColors.accentWarningDark,
          border: Color(0xFFFFE1B3),
          iconBackground: Color(0xFFFFEDC8),
        );
      case ReportSurfaceTone.danger:
        return const _ReportSurfacePalette(
          background: Color(0xFFFFF1F0),
          foreground: AppColors.accentDanger,
          border: Color(0xFFF7D2CF),
          iconBackground: Color(0xFFFDE3E1),
        );
      case ReportSurfaceTone.neutral:
        return _ReportSurfacePalette(
          background: AppColors.inputFill,
          foreground: AppColors.textSecondary,
          border: AppColors.divider.withValues(alpha: 0.8),
          iconBackground: AppColors.panelBackground,
        );
    }
  }
}
