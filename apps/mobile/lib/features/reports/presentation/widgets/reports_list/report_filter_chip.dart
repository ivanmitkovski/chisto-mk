import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';

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
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.radius14,
              vertical: AppSpacing.sm,
            ),
            constraints: const BoxConstraints(minHeight: 44),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : AppColors.inputFill,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.divider,
                width: 0.5,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: AppTypography.chipLabel.copyWith(
                color: selected ? AppColors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
