import 'dart:async';

import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/shared/widgets/organisms/app_surface/report_surface_aliases.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_events/src/domain/models/eco_event.dart';
import 'package:feature_events/src/domain/repositories/events_repository.dart';
import 'package:feature_events/src/presentation/view_models/participants_peek_view_model.dart';
import 'package:feature_events/src/presentation/widgets/event_detail/avatar_stack.dart';
import 'package:feature_events/src/presentation/widgets/event_detail/event_detail_surface_decoration.dart';
import 'package:feature_events/src/presentation/widgets/event_detail/participant_roster_sheet.dart';
import 'package:feature_events/src/presentation/widgets/events_modal_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:feature_events/src/presentation/widgets/event_detail/attendee_list_sheet.dart'
    show AttendeePreview, AttendeeSort, orderPreviewsForAvatarStack;
export 'package:feature_events/src/presentation/widgets/event_detail/avatar_stack.dart'
    show AvatarStack;
export 'package:feature_events/src/presentation/widgets/event_detail/participant_roster_sheet.dart'
    show ParticipantRosterSheetBody, mergeParticipantPreviews;

class ParticipantsSection extends ConsumerStatefulWidget {
  const ParticipantsSection({super.key, required this.event, this.repository});

  final EcoEvent event;
  final EventsRepository? repository;

  @override
  ConsumerState<ParticipantsSection> createState() =>
      _ParticipantsSectionState();
}

class _ParticipantsSectionState extends ConsumerState<ParticipantsSection> {
  EcoEvent get event => widget.event;

  ParticipantsPeekViewModelProvider get _peekProvider =>
      participantsPeekViewModelProvider(event);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _configureAndLoad();
    });
  }

  @override
  void didUpdateWidget(covariant ParticipantsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.event.id != event.id ||
        oldWidget.event.participantCount != event.participantCount ||
        oldWidget.repository != widget.repository) {
      _configureAndLoad();
    }
  }

  void _configureAndLoad() {
    final ParticipantsPeekViewModel notifier = ref.read(_peekProvider.notifier);
    if (widget.repository != null) {
      notifier.setRepository(widget.repository!);
    }
    unawaited(notifier.loadPeek(youLabel: context.l10n.eventsParticipantsYou));
  }

  void _showAttendeeList(BuildContext context) {
    showEventsSurfaceModal<void>(
      context: context,
      builder: (BuildContext ctx) {
        return ReportSheetScaffold(
          title: ctx.l10n.eventsParticipantsTitle,
          subtitle: ctx.l10n.eventsCardParticipantsJoined(
            event.participantCount,
          ),
          maxHeightFactor: 0.84,
          // Single horizontal inset (md = 16) for title, divider, search, tabs, and list.
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          child: ParticipantRosterSheetBody(event: event),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ParticipantsPeekState peek = ref.watch(_peekProvider);
    final TextTheme textTheme = Theme.of(context).textTheme;
    final int count = event.participantCount;

    return Semantics(
      button: true,
      label: count > 0
          ? context.l10n.eventsParticipantsViewSemantic(count)
          : context.l10n.eventsParticipantsViewRosterSemantic,
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: () => _showAttendeeList(context),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: EventDetailSurfaceDecoration.detailModule(),
            child: Row(
              children: <Widget>[
                AvatarStack(
                  count: count,
                  event: event,
                  previews: peek.peekFailed ? null : peek.peekPreviews,
                  isLoadingPeek: peek.peekLoading,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        event.isJoined && count > 1
                            ? context.l10n.eventsParticipantsYouAndOthers(
                                count - 1,
                              )
                            : context.l10n.eventsParticipantsVolunteersJoined(
                                count,
                              ),
                        style: AppTypography.eventsGroupedRowPrimary(textTheme),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (event.maxParticipants != null)
                        Padding(
                          padding: const EdgeInsets.only(
                            top: AppSpacing.xxs / 2,
                          ),
                          child: Text(
                            context.l10n.eventsParticipantsSpotsLeft(
                              (event.maxParticipants! - count).clamp(
                                0,
                                1000000,
                              ),
                            ),
                            style: AppTypography.eventsListCardMeta(textTheme),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if (event.checkedInCount > 0 &&
                          (event.status == EcoEventStatus.inProgress ||
                              event.status == EcoEventStatus.completed))
                        Padding(
                          padding: const EdgeInsets.only(
                            top: AppSpacing.xxs / 2,
                          ),
                          child: Text(
                            context.l10n.eventsParticipantsCheckedInCount(
                              event.checkedInCount,
                              count,
                            ),
                            style: AppTypography.eventsCaptionStrong(
                              textTheme,
                              color: AppColors.primaryDark,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 16,
                  color: AppColors.textMuted.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
