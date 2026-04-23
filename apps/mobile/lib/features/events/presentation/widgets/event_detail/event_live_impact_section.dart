import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/event_detail_surface_decoration.dart';

/// Live counters for volunteers, check-ins, and organizer-reported bags (in-progress events).
class EventLiveImpactSection extends StatelessWidget {
  const EventLiveImpactSection({super.key, required this.event});

  final EcoEvent event;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final double estKg = event.liveReportedBagsCollected * 3.2;

    return Semantics(
      container: true,
      label: context.l10n.eventsLivePulseTitle,
      child: DecoratedBox(
        decoration: EventDetailSurfaceDecoration.detailModule(),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                context.l10n.eventsLivePulseTitle,
                style: AppTypography.eventsPanelTitle(textTheme),
              ),
              const SizedBox(height: AppSpacing.sm),
              _line(
                context,
                context.l10n.eventsLivePulseVolunteers(event.participantCount),
              ),
              _line(
                context,
                context.l10n.eventsLivePulseCheckIns(event.checkedInCount),
              ),
              _line(
                context,
                context.l10n.eventsLivePulseBags(
                  event.liveReportedBagsCollected,
                  estKg.toStringAsFixed(1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _line(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(
        text,
        style: AppTypography.eventsBodyProse(Theme.of(context).textTheme),
      ),
    );
  }
}
