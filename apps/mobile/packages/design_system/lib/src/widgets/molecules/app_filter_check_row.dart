import 'package:design_system/src/theme/app_colors.dart';
import 'package:design_system/src/theme/app_spacing.dart';
import 'package:design_system/src/theme/app_typography.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Multi-select filter row with optional status dot, icon, and trailing checkmark.
class AppFilterCheckRow extends StatelessWidget {
  const AppFilterCheckRow({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.leadingDotColor,
    this.leadingIcon,
    this.semanticLabel,
    this.semanticHint,
    this.showDivider = true,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? leadingDotColor;
  final IconData? leadingIcon;
  final String? semanticLabel;
  final String? semanticHint;
  final bool showDivider;

  static const double _rowHorizontalPadding = AppSpacing.md;
  static const double _leadingSlotWidth = 14;

  double get _dividerIndent {
    if (leadingDotColor != null || leadingIcon != null) {
      return _rowHorizontalPadding + _leadingSlotWidth + AppSpacing.sm;
    }
    return _rowHorizontalPadding;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(
          button: true,
          selected: isSelected,
          label: semanticLabel ?? label,
          hint: semanticHint,
          child: Material(
            color: AppColors.transparent,
            child: InkWell(
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 44),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _rowHorizontalPadding,
                    vertical: AppSpacing.xs,
                  ),
                  child: Row(
                    children: <Widget>[
                      if (leadingIcon != null) ...<Widget>[
                        Icon(
                          leadingIcon,
                          size: 16,
                          color: isSelected
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ] else if (leadingDotColor != null) ...<Widget>[
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: leadingDotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.textTheme.bodyMedium!.copyWith(
                            color: isSelected
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: Icon(
                          isSelected
                              ? CupertinoIcons.checkmark_circle_fill
                              : CupertinoIcons.circle,
                          size: 22,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.divider.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 0.5,
            indent: _dividerIndent,
            endIndent: _rowHorizontalPadding,
            color: AppColors.divider.withValues(alpha: 0.5),
          ),
      ],
    );
  }
}
