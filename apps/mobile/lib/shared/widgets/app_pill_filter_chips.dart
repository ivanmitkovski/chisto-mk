import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

class AppPillFilterChips extends StatelessWidget {
  const AppPillFilterChips({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    this.semanticLabelPrefix = 'Filter',
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final String semanticLabelPrefix;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: labels.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(width: AppSpacing.xs),
        itemBuilder: (BuildContext context, int index) {
          final bool isActive = index == selectedIndex;
          final String label = labels[index];
          return Semantics(
            button: true,
            selected: isActive,
            label: '$semanticLabelPrefix $label',
            child: Material(
              color: AppColors.transparent,
              child: InkWell(
                onTap: () {
                  if (index != selectedIndex) {
                    AppHaptics.tap();
                    onSelected(index);
                  }
                },
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                child: AnimatedContainer(
                  duration: AppMotion.fast,
                  curve: AppMotion.emphasized,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : AppColors.panelBackground,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    border: Border.all(
                      color: isActive ? AppColors.primary : AppColors.divider,
                      width: 1.2,
                    ),
                  ),
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w500,
                          color: isActive
                              ? AppColors.primaryDark
                              : AppColors.textSecondary,
                          letterSpacing: -0.2,
                        ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
