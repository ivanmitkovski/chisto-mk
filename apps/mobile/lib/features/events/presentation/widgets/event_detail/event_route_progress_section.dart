import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/domain/models/event_pulse_route_evidence.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/event_detail_surface_decoration.dart';

/// Horizontal strip summarizing route segment states.
class EventRouteProgressSection extends StatelessWidget {
  const EventRouteProgressSection({super.key, required this.event});

  final EcoEvent event;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: context.l10n.eventsRouteProgressTitle,
      child: DecoratedBox(
        decoration: EventDetailSurfaceDecoration.detailModule(),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                context.l10n.eventsRouteProgressTitle,
                style: AppTypography.eventsPanelTitle(textTheme),
              ),
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: event.routeSegments.length,
                  separatorBuilder: (_, int index) => SizedBox(
                    key: ValueKey<int>(index),
                    width: AppSpacing.xs,
                  ),
                  itemBuilder: (BuildContext context, int i) {
                    final EventRouteSegmentModel s = event.routeSegments[i];
                    final Color bg = s.isCompleted
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : s.status == 'claimed'
                        ? AppColors.accentWarning.withValues(alpha: 0.15)
                        : AppColors.textMuted.withValues(alpha: 0.12);
                    final String label = s.label?.trim().isNotEmpty == true
                        ? s.label!.trim()
                        : '${i + 1}';
                    return Chip(
                      avatar: Icon(
                        s.isCompleted
                            ? CupertinoIcons.checkmark_circle_fill
                            : CupertinoIcons.circle,
                        size: 16,
                        color: s.isCompleted ? AppColors.primaryDark : AppColors.textMuted,
                      ),
                      label: Text(label),
                      backgroundColor: bg,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
