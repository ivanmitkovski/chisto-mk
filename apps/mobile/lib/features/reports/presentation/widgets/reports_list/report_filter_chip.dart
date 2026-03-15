import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';

class ReportFilterChip extends StatelessWidget {
  const ReportFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '$label filter${selected ? ' selected' : ''}',
      hint: 'Double-tap to filter reports by $label.',
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          child: AnimatedContainer(
            duration: AppMotion.medium,
            curve: AppMotion.emphasized,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.radius14, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : AppColors.inputFill,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.divider,
                width: 0.5,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.white : AppColors.textSecondary,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
