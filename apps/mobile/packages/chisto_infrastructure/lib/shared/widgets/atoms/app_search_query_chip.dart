import 'package:design_system/design_system.dart';
import 'package:feature_home/src/presentation/utils/map_search_highlight.dart';
import 'package:flutter/material.dart';

/// Tappable search query chip used in recent/suggestion shelves.
class AppSearchQueryChip extends StatelessWidget {
  const AppSearchQueryChip({
    super.key,
    required this.label,
    required this.onTap,
    this.leadingIcon,
    this.highlightQuery,
    this.semanticLabel,
    this.maxLabelWidth = 220,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? leadingIcon;
  final String? highlightQuery;
  final String? semanticLabel;
  final double maxLabelWidth;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool disableAnimations = MediaQuery.disableAnimationsOf(context);
    final TextStyle baseLabelStyle = AppTypography.chipLabel(
      textTheme,
    ).copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w500);
    final TextStyle emphasisLabelStyle = baseLabelStyle.copyWith(
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w700,
    );

    return Semantics(
      button: true,
      label: semanticLabel ?? label,
      excludeSemantics: semanticLabel != null,
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
          child: AnimatedContainer(
            duration: disableAnimations ? Duration.zero : AppMotion.fast,
            curve: AppMotion.emphasized,
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.panelBackground,
              borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              border: Border.all(
                color: AppColors.divider.withValues(alpha: 0.85),
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (leadingIcon != null) ...<Widget>[
                  Icon(
                    leadingIcon,
                    size: AppSpacing.iconSm,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                ],
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxLabelWidth),
                  child: Text.rich(
                    TextSpan(
                      children: mapSearchHighlightSpans(
                        text: label,
                        rawQuery: highlightQuery ?? '',
                        baseStyle: baseLabelStyle,
                        emphasisStyle: emphasisLabelStyle,
                      ),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
