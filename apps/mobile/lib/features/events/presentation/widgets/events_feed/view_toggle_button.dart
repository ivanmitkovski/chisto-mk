import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';

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
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        selected: selected,
        label: tooltip,
        child: Material(
          color: AppColors.transparent,
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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : AppColors.panelBackground,
                borderRadius: BorderRadius.circular(AppSpacing.radius10),
              ),
              child: Icon(
                icon,
                size: 20,
                color: selected ? AppColors.primaryDark : AppColors.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
