import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';

/// Completed-event callouts: organizer pending after-photos, attendee thank-you.
class EventCompletedDetailCallouts extends StatelessWidget {
  const EventCompletedDetailCallouts({super.key, required this.event});

  final EcoEvent event;

  @override
  Widget build(BuildContext context) {
    if (event.status != EcoEventStatus.completed) {
      return const SizedBox.shrink();
    }

    if (event.isOrganizer && !event.hasAfterImages) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ReportInfoBanner(
            title: context.l10n.eventsOrganizerDetailPendingAfterPhotosTitle,
            message: context.l10n.eventsOrganizerDetailPendingAfterPhotosMessage,
            icon: CupertinoIcons.camera_fill,
            tone: ReportSurfaceTone.accent,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.l10n.eventsAfterPhotosOrganizerEmptyHint,
            style: AppTypography.eventsSupportingCaption(
              Theme.of(context).textTheme,
            ),
          ),
        ],
      );
    }

    if (event.isJoined && !event.isOrganizer) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.panelBackground,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(color: AppColors.divider.withValues(alpha: 0.85)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              context.l10n.eventsAttendeeCompletedTitle,
              style: AppTypography.eventsSheetTitle(
                Theme.of(context).textTheme,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              context.l10n.eventsAttendeeCompletedBody,
              style: AppTypography.eventsBodyMuted(
                Theme.of(context).textTheme,
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
