import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Back-compat aliases for map filter tests and call sites.
typedef MapFilterInsetGroup = AppFilterInsetGroup;

typedef MapFilterCheckRow = AppFilterCheckRow;

typedef MapFilterSummaryChipShelf = AppFilterSummaryChipShelf;

/// Single toggle row for boolean filter options.
class MapFilterSwitchRow extends StatelessWidget {
  const MapFilterSwitchRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.semanticLabel,
    this.showDivider = false,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? semanticLabel;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Semantics(
          label: semanticLabel ?? title,
          hint: subtitle,
          toggled: value,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        style: AppTypography.textTheme.bodyMedium!.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs / 2),
                      Text(
                        subtitle,
                        style: AppTypographySurfaces.homeMutedCaption(
                          textTheme,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(value: value, onChanged: onChanged),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 0.5,
            indent: AppSpacing.md,
            endIndent: AppSpacing.md,
            color: AppColors.divider.withValues(alpha: 0.5),
          ),
      ],
    );
  }
}
