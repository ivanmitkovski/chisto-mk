import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';

const double _kControlIconSize = 20;

class ViewToggleButton extends StatelessWidget {
  const ViewToggleButton({
    super.key,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  /// Shown as [Tooltip] and as the screen reader label (long-press for tooltip on iOS).
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color surface = colorScheme.surface;
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        selected: selected,
        label: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            customBorder: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radius10),
            ),
            child: AnimatedContainer(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : AppMotion.fast,
              curve: AppMotion.emphasized,
              width: AppSpacing.eventsFeedToolbarControlSize,
              height: AppSpacing.eventsFeedToolbarControlSize,
              decoration: BoxDecoration(
                color: selected ? AppColors.feedPillSelectedFill : surface,
                borderRadius: BorderRadius.circular(AppSpacing.radius10),
                border: Border.all(
                  color: selected
                      ? AppColors.feedPillSelectedBorder
                      : AppColors.divider,
                ),
              ),
              child: Icon(
                icon,
                size: _kControlIconSize,
                color: selected
                    ? AppColors.feedPillSelectedForeground
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
