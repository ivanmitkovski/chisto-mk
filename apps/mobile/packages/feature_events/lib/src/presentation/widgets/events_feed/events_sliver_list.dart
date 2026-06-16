import 'package:design_system/design_system.dart';
import 'package:feature_events/src/domain/models/eco_event.dart';
import 'package:feature_events/src/presentation/widgets/eco_event_card.dart';
import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xs,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        child: Text(
          title,
          style: AppTypography.eventsFeedSectionTitle(
            Theme.of(context).textTheme,
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
    this.userLatitude,
    this.userLongitude,
    this.startIndex = 0,
    this.animateEntrance = false,
  });

  final List<EcoEvent> events;
  final ValueChanged<EcoEvent> onTap;
  final double? userLatitude;
  final double? userLongitude;
  final int startIndex;
  final bool animateEntrance;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      sliver: SliverList.separated(
        itemCount: events.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (BuildContext context, int index) {
          final EcoEvent event = events[index];
          final EcoEventCard card = EcoEventCard(
            key: ValueKey<String>(event.id),
            event: event,
            onTap: () => onTap(event),
            userLatitude: userLatitude,
            userLongitude: userLongitude,
          );
          if (!animateEntrance) {
            return card;
          }
          return AnimatedListItem(index: startIndex + index, child: card);
        },
      ),
    );
  }
}
