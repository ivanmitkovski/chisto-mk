import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

const double _kChipControlHeight = 48;
const double _kChipSelectedBorderAlpha = 0.5;
const double _kChipUnselectedBorderAlpha = 0.8;

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
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: _kChipControlHeight,
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
              color: Colors.transparent,
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
                        ? colorScheme.primaryContainer
                        : colorScheme.surface,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                    border: Border.all(
                      color: isActive
                          ? colorScheme.primary.withValues(alpha: _kChipSelectedBorderAlpha)
                          : colorScheme.outlineVariant.withValues(alpha: _kChipUnselectedBorderAlpha),
                      width: 1.2,
                    ),
                  ),
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight:
                              isActive ? FontWeight.w600 : FontWeight.w500,
                          color: isActive
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurfaceVariant,
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
