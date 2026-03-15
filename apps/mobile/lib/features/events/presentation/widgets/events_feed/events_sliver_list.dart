import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/eco_event_card.dart';
import 'package:chisto_mobile/shared/widgets/animated_list_item.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.xs, AppSpacing.lg, AppSpacing.sm,
        ),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
        ),
      ),
    );
  }
}

class EventsSliverList extends StatelessWidget {
  const EventsSliverList({
    super.key,
    required this.events,
    required this.onTap,
    this.startIndex = 0,
  });

  final List<EcoEvent> events;
  final ValueChanged<EcoEvent> onTap;
  final int startIndex;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      sliver: SliverList.separated(
        itemCount: events.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (BuildContext context, int index) {
          final EcoEvent event = events[index];
          return AnimatedListItem(
            index: startIndex + index,
            child: EcoEventCard(
              event: event,
              onTap: () => onTap(event),
            ),
          );
        },
      ),
    );
  }
}
