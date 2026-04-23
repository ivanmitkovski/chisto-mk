import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/data/event_feedback_local_cache.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/utils/event_recurrence_rrule_summary.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/event_detail_layout.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/event_detail_surface_decoration.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/event_detail_stagger.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/staggered_section.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/title_section.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/event_detail_facts_section.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/gear_section.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/description_section.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/participants_section.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/organizer_section.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/after_photos_gallery.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/completed_trash_bags_section.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/event_completed_detail_callouts.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/event_live_impact_section.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/event_evidence_strip_section.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/event_route_progress_section.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/impact_summary_section.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/reminder_section.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/attendee_check_in_banner.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/organizer_analytics_section.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/weather_card.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

/// Vertical section order (product + screen reader narrative):
/// title → contextual banners → facts (where / when / category / scale / difficulty) →
/// facts cards (when / where / meta chips) → weather (when coordinates exist) → gear → description → participation block
/// (check-in + reminder when joined) → participants → organizer → organizer
/// analytics (non-upcoming) → after photos → impact receipt link (in progress / completed) →
/// trash bags (organizer, completed) → impact summary (completed).
/// Event chat opens from the hero toolbar when the user may access it.
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
    this.onSaveBagsCollected,
    this.onOpenImpactReceipt,
  });

  final EcoEvent event;
  final VoidCallback onToggleReminder;
  final VoidCallback onExportCalendar;
  final EventFeedbackSnapshot? feedbackSnapshot;
  final VoidCallback onEditFeedback;
  final ValueChanged<int> onImageTap;
  final ValueChanged<String>? onOpenSeriesOccurrence;

  /// When non-null and the event is completed + organizer, shows inline trash-bag count.
  final Future<void> Function(int bagsCollected)? onSaveBagsCollected;

  /// Opens the impact receipt screen (in progress or completed only).
  final VoidCallback? onOpenImpactReceipt;

  @override
  Widget build(BuildContext context) {
    final Future<void> Function(int bagsCollected)? saveBags =
        onSaveBagsCollected;

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
        if (event.status == EcoEventStatus.inProgress) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          StaggeredSection(
            delay: EventDetailStagger.livePulse,
            child: EventLiveImpactSection(event: event),
          ),
        ],
        if (onOpenImpactReceipt != null &&
            (event.status == EcoEventStatus.inProgress ||
                event.status == EcoEventStatus.completed)) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          StaggeredSection(
            delay: EventDetailStagger.impactReceiptLink,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppSpacing.md),
                onTap: () {
                  AppHaptics.tap();
                  onOpenImpactReceipt!();
                },
                child: Ink(
                  decoration: EventDetailSurfaceDecoration.detailModule(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          CupertinoIcons.doc_text_fill,
                          color: AppColors.primaryDark,
                          size: 22,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            context.l10n.eventsImpactReceiptViewCta,
                            style: AppTypography.eventsGroupedRowPrimary(
                              Theme.of(context).textTheme,
                            ),
                          ),
                        ),
                        Icon(
                          CupertinoIcons.chevron_forward,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
        if (event.routeSegments.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          StaggeredSection(
            delay: EventDetailStagger.routeProgress,
            child: EventRouteProgressSection(event: event),
          ),
        ],
        if (event.evidenceStrip.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          StaggeredSection(
            delay: EventDetailStagger.evidenceStrip,
            child: EventEvidenceStripSection(items: event.evidenceStrip),
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        Semantics(
          container: true,
          label: context.l10n.eventsDetailGroupedPanelSemantic,
          child: StaggeredSection(
            delay: EventDetailStagger.groupedPanel,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                EventDetailFactsSection(
                  event: event,
                  onExportCalendar: onExportCalendar,
                ),
                if (event.isRecurring) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  DecoratedBox(
                    decoration: EventDetailSurfaceDecoration.detailModule(),
                    child: _RecurrenceRow(
                      event: event,
                      onOpenSeriesOccurrence: onOpenSeriesOccurrence,
                    ),
                  ),
                ],
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
        if (event.isOrganizer &&
            event.status != EcoEventStatus.upcoming) ...<Widget>[
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
            child: AfterPhotosGallery(event: event, onImageTap: onImageTap),
          ),
        ),
        if (event.status == EcoEventStatus.completed &&
            event.isOrganizer &&
            saveBags != null) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          StaggeredSection(
            delay: EventDetailStagger.afterPhotos + 2,
            child: CompletedTrashBagsSection(
              initialBags: feedbackSnapshot?.bagsCollected ?? 0,
              onSave: saveBags,
            ),
          ),
        ],
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

/// Recurring series summary and prev/next occurrence controls.
class _RecurrenceRow extends StatelessWidget {
  const _RecurrenceRow({required this.event, this.onOpenSeriesOccurrence});

  final EcoEvent event;
  final ValueChanged<String>? onOpenSeriesOccurrence;

  @override
  Widget build(BuildContext context) {
    final int? total = event.recurrenceSeriesTotal;
    final int? pos = event.recurrenceSeriesPosition;
    final String primaryLabel = total != null && pos != null && total > 1
        ? context.l10n.eventsRecurrenceSeriesLabel(pos, total)
        : context.l10n.eventsRecurrencePartOfSeries;
    final String? rruleLine = summarizeRecurrenceRule(
      event.recurrenceRule,
      context.l10n,
    );
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
          style: AppTypography.eventsGroupedRowPrimary(
            Theme.of(context).textTheme,
          ),
        ),
        if (rruleLine != null) ...<Widget>[
          const SizedBox(height: 2),
          Text(
            rruleLine,
            style: AppTypography.eventsListCardMeta(
              Theme.of(context).textTheme,
            ),
          ),
        ],
      ],
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: kEventDetailGroupedRowMinHeight,
      ),
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
