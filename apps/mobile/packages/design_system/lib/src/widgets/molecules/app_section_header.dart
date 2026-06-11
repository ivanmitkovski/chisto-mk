import 'package:design_system/src/theme/app_colors.dart';
import 'package:design_system/src/theme/app_spacing.dart';
import 'package:design_system/src/theme/app_typography.dart';
import 'package:design_system/src/theme/app_typography_surfaces.dart';
import 'package:flutter/material.dart';

enum AppSectionHeaderVariant { detail, feed }

class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.padding,
    this.variant = AppSectionHeaderVariant.detail,
    this.titleStyle,
  });

  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;
  final AppSectionHeaderVariant variant;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    final TextStyle resolvedTitleStyle =
        titleStyle ?? _titleStyleForVariant(context, variant);
    return Padding(
      padding:
          padding ??
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              title,
              style: resolvedTitleStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (trailing != null) ...<Widget>[
            const SizedBox(width: AppSpacing.sm),
            trailing!,
          ],
        ],
      ),
    );
  }

  TextStyle _titleStyleForVariant(
    BuildContext context,
    AppSectionHeaderVariant variant,
  ) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    switch (variant) {
      case AppSectionHeaderVariant.detail:
        return AppTypography.sectionHeader(AppTypography.textTheme);
      case AppSectionHeaderVariant.feed:
        return AppTypography.sectionHeader(
          AppTypography.textTheme,
        ).copyWith(fontWeight: FontWeight.w700);
    }
  }
}

/// Compact text action aligned with [AppSectionHeader] titles.
class AppSectionHeaderAction extends StatelessWidget {
  const AppSectionHeaderAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.semanticLabel,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: semanticLabel ?? label,
      child: TextButton(
        onPressed: enabled ? onPressed : null,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          disabledForegroundColor: AppColors.textSecondary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxs,
            vertical: AppSpacing.xxs,
          ),
          minimumSize: const Size(0, 36),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: AppTypographySurfaces.sectionHeaderAction(textTheme),
        ),
        child: Text(
          label,
          maxLines: 2,
          softWrap: true,
          overflow: TextOverflow.visible,
        ),
      ),
    );
  }
}
