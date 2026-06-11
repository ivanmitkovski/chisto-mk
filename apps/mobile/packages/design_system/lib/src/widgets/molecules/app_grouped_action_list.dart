import 'package:design_system/src/theme/app_colors.dart';
import 'package:design_system/src/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Single inset-grouped card for sheet pickers (category, gear, scale, …).
///
/// Rows should use [AppActionTile] with [AppActionTileVariant.grouped] so each
/// option shares one surface and hairline dividers instead of gray gaps.
class AppGroupedActionList extends StatelessWidget {
  const AppGroupedActionList({super.key, required this.children});

  final List<Widget> children;

  /// Aligns dividers with the primary text column of grouped [AppActionTile]s.
  static const double dividerLeadingInset =
      AppSpacing.sm + 40 + AppSpacing.md;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    final BorderRadius borderRadius = BorderRadius.circular(AppSpacing.radiusLg);
    final List<Widget> items = <Widget>[];
    for (int i = 0; i < children.length; i++) {
      items.add(children[i]);
      if (i < children.length - 1) {
        items.add(
          Row(
            children: <Widget>[
              const SizedBox(width: dividerLeadingInset),
              Expanded(
                child: ColoredBox(
                  color: AppColors.divider.withValues(alpha: 0.75),
                  child: const SizedBox(height: 0.5),
                ),
              ),
            ],
          ),
        );
      }
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: borderRadius,
        border: Border.all(
          color: AppColors.divider.withValues(alpha: 0.75),
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: items,
        ),
      ),
    );
  }
}
