import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/data/event_feedback_local_cache.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/staggered_section.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/title_section.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/location_chip.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/date_time_section.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/category_section.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/event_details_grid.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/gear_section.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/description_section.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/participants_section.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/organizer_section.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/after_photos_gallery.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/impact_summary_section.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/reminder_section.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/attendee_check_in_banner.dart';

class DetailContent extends StatelessWidget {
  const DetailContent({
    super.key,
    required this.event,
    required this.onToggleReminder,
    required this.onExportCalendar,
    required this.feedbackSnapshot,
    required this.onEditFeedback,
    required this.onImageTap,
  });

  final EcoEvent event;
  final VoidCallback onToggleReminder;
  final VoidCallback onExportCalendar;
  final EventFeedbackSnapshot? feedbackSnapshot;
  final VoidCallback onEditFeedback;
  final ValueChanged<int> onImageTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        StaggeredSection(
          delay: 0,
          child: TitleSection(event: event),
        ),
        const SizedBox(height: AppSpacing.lg),
        StaggeredSection(
          delay: 50,
          child: LocationChip(event: event),
        ),
        const SizedBox(height: AppSpacing.lg),
        StaggeredSection(
          delay: 100,
          child: DateTimeSection(
            event: event,
            onExportCalendar: onExportCalendar,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        StaggeredSection(
          delay: 150,
          child: CategorySection(event: event),
        ),
        const SizedBox(height: AppSpacing.lg),
        StaggeredSection(
          delay: 200,
          child: EventDetailsGrid(event: event),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (event.gear.isNotEmpty) ...<Widget>[
          StaggeredSection(
            delay: 250,
            child: GearSection(event: event),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
        StaggeredSection(
          delay: 300,
          child: DescriptionSection(event: event),
        ),
        const SizedBox(height: AppSpacing.lg),
        StaggeredSection(
          delay: 350,
          child: ParticipantsSection(event: event),
        ),
        const SizedBox(height: AppSpacing.lg),
        StaggeredSection(
          delay: 400,
          child: OrganizerSection(event: event),
        ),
        if (event.hasAfterImages) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          StaggeredSection(
            delay: 405,
            child: AfterPhotosGallery(
              event: event,
              onImageTap: onImageTap,
            ),
          ),
        ],
        if (event.status == EcoEventStatus.completed) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          StaggeredSection(
            delay: 408,
            child: ImpactSummarySection(
              snapshot: feedbackSnapshot,
              onEdit: onEditFeedback,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        StaggeredSection(
          delay: 410,
          child: ReminderSection(
            event: event,
            onToggleReminder: onToggleReminder,
          ),
        ),
        if (event.isJoined &&
            !event.isOrganizer &&
            event.status == EcoEventStatus.inProgress) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          StaggeredSection(
            delay: 415,
            child: AttendeeCheckInBanner(event: event),
          ),
        ],
      ],
    );
  }
}
