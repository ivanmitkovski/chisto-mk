import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_events/src/domain/models/eco_event.dart';
import 'package:feature_events/src/presentation/widgets/event_detail/event_detail_surface_decoration.dart';
import 'package:feature_events/src/presentation/widgets/event_detail/impact_summary_section.dart';
import 'package:flutter/material.dart';

/// Live counters for volunteers, check-ins, and organizer-reported bags (in-progress events).
///
/// Fills the detail body gutter horizontally (parent [Column] uses [CrossAxisAlignment.start],
/// so width must be explicit).
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
      child: SizedBox(
        width: double.infinity,
        child: DecoratedBox(
          decoration: EventDetailSurfaceDecoration.detailModule(),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        context.l10n.eventsLivePulseTitle,
                        style: AppTypography.eventsPanelTitle(textTheme),
                      ),
                    ),
                    ImpactBadge(label: context.l10n.eventsAnalyticsLive),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: <Widget>[
                    ImpactBadge(
                      label: context.l10n.eventsLivePulseVolunteers(
                        event.participantCount,
                      ),
                    ),
                    ImpactBadge(
                      label: context.l10n.eventsLivePulseCheckIns(
                        event.checkedInCount,
                      ),
                    ),
                    ImpactBadge(
                      label: context.l10n.eventsLivePulseBags(
                        event.liveReportedBagsCollected,
                        estKg.toStringAsFixed(1),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
