import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event_filter.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

export 'package:chisto_mobile/features/events/domain/models/eco_event_filter.dart';

class EventsFilterChips extends StatelessWidget {
  const EventsFilterChips({
    super.key,
    required this.active,
    required this.onSelected,
  });

  final EcoEventFilter active;
  final ValueChanged<EcoEventFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        itemCount: EcoEventFilter.values.length,
        separatorBuilder: (BuildContext context, int index) =>
            const SizedBox(width: AppSpacing.xs),
        itemBuilder: (BuildContext context, int index) {
          final EcoEventFilter filter = EcoEventFilter.values[index];
          final bool isActive = filter == active;
          return Semantics(
            button: true,
            selected: isActive,
            label: '${filter.label} events filter',
            child: Material(
              color: AppColors.transparent,
              child: InkWell(
                onTap: () {
                  if (filter != active) {
                    AppHaptics.tap();
                    onSelected(filter);
                  }
                },
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                child: AnimatedContainer(
                  duration: AppMotion.fast,
                  curve: AppMotion.emphasized,
                  padding:
                      const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.radiusSm,
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
                    filter.label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
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
