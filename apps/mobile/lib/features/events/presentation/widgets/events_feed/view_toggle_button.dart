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
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radius10),
          ),
          child: AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.emphasized,
            width: 40,
            height: 40,
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
    );
  }
}
