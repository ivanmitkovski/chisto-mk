import 'dart:async';

import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/shared/widgets/organisms/app_surface/report_surface_aliases.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_events/src/domain/models/eco_event.dart';
import 'package:feature_events/src/presentation/utils/event_calendar_add_feedback.dart';
import 'package:feature_events/src/presentation/utils/event_calendar_add_result.dart';
import 'package:feature_events/src/presentation/utils/event_calendar_date_format.dart';
import 'package:feature_events/src/presentation/utils/event_calendar_export.dart';
import 'package:feature_events/src/presentation/widgets/event_detail/event_detail_grouped_metadata_row.dart';
import 'package:feature_events/src/presentation/widgets/event_detail/event_detail_surface_decoration.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DateTimeSection extends StatelessWidget {
  const DateTimeSection({
    super.key,
    required this.event,
    this.embeddedInGroupedPanel = false,
  });

  final EcoEvent event;

  /// When true, omits outer card chrome (use inside [EventDetailGroupedPanel]).
  final bool embeddedInGroupedPanel;

  void _showDateInfo(BuildContext context) {
    final Duration diff = event.startDateTime.difference(DateTime.now());
    final String relative;
    if (diff.isNegative) {
      final int daysAgo = diff.inDays.abs();
      relative = daysAgo == 0
          ? context.l10n.eventsDateRelativeEarlierToday
          : context.l10n.eventsDateRelativeDaysAgo(daysAgo);
    } else if (diff.inDays == 0) {
      relative = context.l10n.eventsDateRelativeToday;
    } else if (diff.inDays == 1) {
      relative = context.l10n.eventsDateRelativeTomorrow;
    } else {
      relative = context.l10n.eventsDateRelativeInDays(diff.inDays);
    }

    AppBottomSheet.show<void>(
      context: context,
      backgroundColor: AppColors.transparent,
      builder: (BuildContext ctx) {
        return ReportSheetScaffold(
          title: ctx.l10n.eventsDateInfoSheetTitle,
          subtitle: formatEventCalendarDate(ctx, event.date),
          fitToContent: true,
          child: _EventDateInfoSheetBody(
            event: event,
            relativeLabel: '$relative · ${event.formattedTimeRange}',
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    final String dateLabel = formatEventCalendarDate(context, event.date);
    final String timeRangeLabel = event.formattedTimeRange;
    final String kmSuffix = context.l10n.eventsLocationDotKm(
      event.siteDistanceKm.toStringAsFixed(1),
    );

    return Semantics(
      button: true,
      label: embeddedInGroupedPanel
          ? '${context.l10n.eventsDateInfoSemantic(dateLabel, timeRangeLabel)} $kmSuffix'
          : context.l10n.eventsDateInfoSemantic(dateLabel, timeRangeLabel),
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: () => _showDateInfo(context),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: embeddedInGroupedPanel
              // ── Embedded: grouped metadata row, no card chrome ────────────
              ? EventDetailGroupedMetadataRow(
                  leading: const EventDetailGroupedMetadataRowLeading(
                    icon: CupertinoIcons.calendar,
                  ),
                  center: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        dateLabel,
                        style: AppTypography.eventsGroupedRowPrimary(textTheme),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text.rich(
                        TextSpan(
                          style: AppTypography.eventsListCardMeta(textTheme),
                          children: <InlineSpan>[
                            TextSpan(text: timeRangeLabel),
                            TextSpan(
                              text: ' $kmSuffix',
                              style: AppTypography.eventsListCardMeta(
                                textTheme,
                              ).copyWith(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                )
              // ── Standalone: prominent card with large icon ─────────────────
              : Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: EventDetailSurfaceDecoration.detailModule(),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: AppSpacing.avatarMd,
                        height: AppSpacing.avatarMd,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                        ),
                        child: const Icon(
                          CupertinoIcons.calendar,
                          size: 22,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              dateLabel,
                              style: AppTypography.eventsGroupedRowPrimary(
                                textTheme,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppSpacing.xxs / 2),
                            Text(
                              timeRangeLabel,
                              style: AppTypography.eventsListCardMeta(
                                textTheme,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        CupertinoIcons.chevron_right,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

/// Date/time sheet body with calendar-add state and feedback.
class _EventDateInfoSheetBody extends StatefulWidget {
  const _EventDateInfoSheetBody({
    required this.event,
    required this.relativeLabel,
  });

  final EcoEvent event;
  final String relativeLabel;

  @override
  State<_EventDateInfoSheetBody> createState() =>
      _EventDateInfoSheetBodyState();
}

class _EventDateInfoSheetBodyState extends State<_EventDateInfoSheetBody> {
  bool _checkingAdded = true;
  bool _inCalendar = false;
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadAddedState());
  }

  Future<void> _loadAddedState() async {
    final bool added = await EventCalendarExport.isAddedToCalendar(
      widget.event,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _inCalendar = added;
      _checkingAdded = false;
    });
  }

  Future<void> _onAddPressed() async {
    if (_adding || _checkingAdded) {
      return;
    }
    setState(() => _adding = true);
    final EventCalendarAddResult result = await EventCalendarExport.requestAdd(
      widget.event,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _adding = false;
      if (result == EventCalendarAddResult.added ||
          result == EventCalendarAddResult.alreadyAdded) {
        _inCalendar = true;
      }
    });
    showEventCalendarAddFeedback(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final bool showAdded = _inCalendar && !_adding;
    final bool busy = _checkingAdded || _adding;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Center(
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Icon(
              showAdded
                  ? CupertinoIcons.checkmark_circle_fill
                  : CupertinoIcons.calendar,
              size: 28,
              color: showAdded ? AppColors.primaryDark : AppColors.primaryDark,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          widget.relativeLabel,
          style: AppTypography.eventsBodyMuted(textTheme),
          textAlign: TextAlign.center,
        ),
        if (showAdded) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.l10n.eventsDetailCalendarAlreadyAdded,
            style: AppTypography.eventsCaptionStrong(
              textTheme,
              color: AppColors.primaryDark,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: showAdded
              ? OutlinedButton.icon(
                  onPressed: busy ? null : _onAddPressed,
                  icon: const Icon(
                    CupertinoIcons.checkmark_circle,
                    size: 18,
                    color: AppColors.primaryDark,
                  ),
                  label: Text(context.l10n.eventsAddToCalendarAlreadyAdded),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.35),
                    ),
                    backgroundColor: AppColors.primary.withValues(alpha: 0.06),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radius14),
                    ),
                    foregroundColor: AppColors.primaryDark,
                  ),
                )
              : OutlinedButton.icon(
                  onPressed: busy ? null : _onAddPressed,
                  icon: busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: AppLoadingIndicator(
                            size: AppLoadingIndicatorSize.sm,
                          ),
                        )
                      : const Icon(
                          CupertinoIcons.calendar_badge_plus,
                          size: 18,
                        ),
                  label: Text(context.l10n.eventsAddToCalendar),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.divider),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radius14),
                    ),
                    foregroundColor: AppColors.textSecondary,
                  ),
                ),
        ),
      ],
    );
  }
}
