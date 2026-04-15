import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/data/event_feedback_local_cache.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/utils/event_recurrence_rrule_summary.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/event_detail_layout.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/event_detail_stagger.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/staggered_section.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/title_section.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/event_detail_chat_row.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/event_detail_grouped_panel.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/location_chip.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/date_time_section.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/category_section.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/event_details_grid.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/gear_section.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/description_section.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/participants_section.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/organizer_section.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/after_photos_gallery.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/event_completed_detail_callouts.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/impact_summary_section.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/reminder_section.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/attendee_check_in_banner.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/organizer_analytics_section.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/weather_card.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

/// Vertical section order (product + screen reader narrative):
/// title → contextual banners → grouped metadata (where / when / category / …) →
/// weather (when coordinates exist) → gear → description → participation block
/// (check-in + reminder when joined) → participants → organizer → organizer
/// analytics (non-upcoming) → after photos → impact summary (completed).
class DetailContent extends StatelessWidget {
  const DetailContent({
    super.key,
    required this.event,
    required this.onToggleReminder,
    required this.onExportCalendar,
    required this.feedbackSnapshot,
    required this.onEditFeedback,
    required this.onImageTap,
    this.onOpenSeriesOccurrence,
    this.onOpenEventChat,
    this.eventChatUnreadCount = 0,
  });

  final EcoEvent event;
  final VoidCallback onToggleReminder;
  final VoidCallback onExportCalendar;
  final EventFeedbackSnapshot? feedbackSnapshot;
  final VoidCallback onEditFeedback;
  final ValueChanged<int> onImageTap;
  final ValueChanged<String>? onOpenSeriesOccurrence;
  final VoidCallback? onOpenEventChat;
  final int eventChatUnreadCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        StaggeredSection(
          delay: EventDetailStagger.title,
          child: TitleSection(event: event),
        ),
        if (event.status == EcoEventStatus.cancelled) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          StaggeredSection(
            delay: EventDetailStagger.cancelledBanner,
            child: ReportInfoBanner(
              message: context.l10n.eventsDetailCancelledCallout,
              icon: CupertinoIcons.xmark_circle_fill,
              tone: ReportSurfaceTone.danger,
            ),
          ),
        ],
        if (event.maxParticipants != null) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          StaggeredSection(
            delay: EventDetailStagger.maxParticipantsBanner,
            child: ReportInfoBanner(
              message: context.l10n.eventsOrganizerDashboardParticipants(
                event.participantCount,
                event.maxParticipants!.toString(),
              ),
              icon: CupertinoIcons.person_2_fill,
              tone: ReportSurfaceTone.neutral,
              emphasis: ReportInfoBannerEmphasis.secondary,
            ),
          ),
        ],
        if (event.maxParticipants != null &&
            event.participantCount >= event.maxParticipants! &&
            !event.isOrganizer) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          StaggeredSection(
            delay: EventDetailStagger.eventFullBanner,
            child: ReportInfoBanner(
              message: context.l10n.eventsEventFull,
              icon: CupertinoIcons.exclamationmark_triangle_fill,
              tone: ReportSurfaceTone.warning,
            ),
          ),
        ],
        if (event.status == EcoEventStatus.completed) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          StaggeredSection(
            delay: EventDetailStagger.completedCallouts,
            child: EventCompletedDetailCallouts(event: event),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Semantics(
          container: true,
          label: context.l10n.eventsDetailGroupedPanelSemantic,
          child: StaggeredSection(
            delay: EventDetailStagger.groupedPanel,
            child: EventDetailGroupedPanel(
              children: <Widget>[
                LocationChip(
                  event: event,
                  embeddedInGroupedPanel: true,
                ),
                DateTimeSection(
                  event: event,
                  onExportCalendar: onExportCalendar,
                  embeddedInGroupedPanel: true,
                ),
                CategorySection(
                  event: event,
                  embeddedInGroupedPanel: true,
                ),
                if (event.scale != null || event.difficulty != null)
                  EventDetailsGrid(
                    event: event,
                    embeddedInGroupedPanel: true,
                  ),
                if (event.isRecurring)
                  _RecurrenceRow(
                    event: event,
                    onOpenSeriesOccurrence: onOpenSeriesOccurrence,
                  ),
                if (onOpenEventChat != null)
                  EventDetailChatRow(
                    unreadCount: eventChatUnreadCount,
                    onOpen: onOpenEventChat!,
                  ),
              ],
            ),
          ),
        ),
        if (event.siteLat != null && event.siteLng != null) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          Semantics(
            container: true,
            label: context.l10n.eventsWeatherForecast,
            child: StaggeredSection(
              delay: EventDetailStagger.weather,
              child: WeatherCard(event: event),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        StaggeredSection(
          delay: EventDetailStagger.gear,
          child: GearSection(event: event),
        ),
        const SizedBox(height: AppSpacing.lg),
        StaggeredSection(
          delay: EventDetailStagger.description,
          child: DescriptionSection(event: event),
        ),
        if (event.isJoined) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          Semantics(
            container: true,
            label: context.l10n.eventsDetailParticipationSemantic,
            child: StaggeredSection(
              delay: EventDetailStagger.participationBlock,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (!event.isOrganizer &&
                      event.status == EcoEventStatus.inProgress) ...<Widget>[
                    AttendeeCheckInBanner(event: event),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  ReminderSection(
                    event: event,
                    onToggleReminder: onToggleReminder,
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        StaggeredSection(
          delay: EventDetailStagger.participants,
          child: ParticipantsSection(event: event),
        ),
        const SizedBox(height: AppSpacing.lg),
        StaggeredSection(
          delay: EventDetailStagger.organizer,
          child: OrganizerSection(event: event),
        ),
        if (event.isOrganizer && event.status != EcoEventStatus.upcoming) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          StaggeredSection(
            delay: EventDetailStagger.organizerAnalytics,
            child: OrganizerAnalyticsSection(event: event),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Semantics(
          container: true,
          label: context.l10n.eventsAfterCleanupTitle,
          child: StaggeredSection(
            delay: EventDetailStagger.afterPhotos,
            child: AfterPhotosGallery(
              event: event,
              onImageTap: onImageTap,
            ),
          ),
        ),
        if (event.status == EcoEventStatus.completed) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          StaggeredSection(
            delay: EventDetailStagger.impactSummary,
            child: ImpactSummarySection(
              snapshot: feedbackSnapshot,
              onEdit: onEditFeedback,
            ),
          ),
        ],
      ],
    );
  }
}

/// Embedded row inside [EventDetailGroupedPanel] for recurring series context.
class _RecurrenceRow extends StatelessWidget {
  const _RecurrenceRow({
    required this.event,
    this.onOpenSeriesOccurrence,
  });

  final EcoEvent event;
  final ValueChanged<String>? onOpenSeriesOccurrence;

  @override
  Widget build(BuildContext context) {
    final int? total = event.recurrenceSeriesTotal;
    final int? pos = event.recurrenceSeriesPosition;
    final String primaryLabel = total != null && pos != null && total > 1
        ? context.l10n.eventsRecurrenceSeriesLabel(pos, total)
        : context.l10n.eventsRecurrencePartOfSeries;
    final String? rruleLine =
        summarizeRecurrenceRule(event.recurrenceRule, context.l10n);
    final String? prevId = event.recurrencePrevEventId;
    final String? nextId = event.recurrenceNextEventId;
    final bool canNavigate = onOpenSeriesOccurrence != null;

    Widget navPrevious(String id) {
      return Semantics(
        button: true,
        label: context.l10n.eventsRecurrenceNavigatePrevious,
        child: IconButton(
          tooltip: context.l10n.eventsRecurrenceNavigatePrevious,
          constraints: const BoxConstraints(
            minWidth: AppSpacing.avatarMd,
            minHeight: AppSpacing.avatarMd,
          ),
          onPressed: () {
            AppHaptics.light();
            onOpenSeriesOccurrence!(id);
          },
          icon: const Icon(
            CupertinoIcons.chevron_back,
            size: 22,
            color: AppColors.primaryDark,
          ),
        ),
      );
    }

    Widget navNext(String id) {
      return Semantics(
        button: true,
        label: context.l10n.eventsRecurrenceNavigateNext,
        child: IconButton(
          tooltip: context.l10n.eventsRecurrenceNavigateNext,
          constraints: const BoxConstraints(
            minWidth: AppSpacing.avatarMd,
            minHeight: AppSpacing.avatarMd,
          ),
          onPressed: () {
            AppHaptics.light();
            onOpenSeriesOccurrence!(id);
          },
          icon: const Icon(
            CupertinoIcons.chevron_forward,
            size: 22,
            color: AppColors.primaryDark,
          ),
        ),
      );
    }

    final Widget textColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          primaryLabel,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
        ),
        if (rruleLine != null) ...<Widget>[
          const SizedBox(height: 2),
          Text(
            rruleLine,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
          ),
        ],
      ],
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: kEventDetailGroupedRowMinHeight),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool narrow = constraints.maxWidth < 320;
            final bool showNav =
                canNavigate && (prevId != null || nextId != null);

            if (narrow && showNav) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Icon(
                        CupertinoIcons.repeat,
                        size: AppSpacing.iconMd,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: textColumn),
                    ],
                  ),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        if (prevId != null) navPrevious(prevId),
                        if (nextId != null) navNext(nextId),
                      ],
                    ),
                  ),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Icon(
                  CupertinoIcons.repeat,
                  size: AppSpacing.iconMd,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: textColumn),
                if (canNavigate && prevId != null) navPrevious(prevId),
                if (canNavigate && nextId != null) navNext(nextId),
              ],
            );
          },
        ),
      ),
    );
  }
}
