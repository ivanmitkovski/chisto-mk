import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/utils/event_calendar_date_format.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/event_detail_grouped_metadata_row.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/event_detail_surface_decoration.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

class DateTimeSection extends StatelessWidget {
  const DateTimeSection({
    super.key,
    required this.event,
    required this.onExportCalendar,
    this.embeddedInGroupedPanel = false,
  });

  final EcoEvent event;
  final VoidCallback onExportCalendar;

  /// When true, omits outer card chrome (use inside [EventDetailGroupedPanel]).
  final bool embeddedInGroupedPanel;

  void _showDateInfo(BuildContext context) {
    AppHaptics.tap();
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

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.transparent,
      builder: (BuildContext ctx) {
        return ReportSheetScaffold(
          title: ctx.l10n.eventsDateInfoSheetTitle,
          subtitle: formatEventCalendarDate(ctx, event.date),
          fitToContent: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: const Icon(
                  CupertinoIcons.calendar,
                  size: 28,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                '$relative · ${event.formattedTimeRange}',
                style: AppTypography.eventsBodyMuted(Theme.of(ctx).textTheme),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    onExportCalendar();
                  },
                  icon: const Icon(
                    CupertinoIcons.calendar_badge_plus,
                    size: 18,
                  ),
                  label: Text(ctx.l10n.eventsAddToCalendar),
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
                              style: AppTypography.eventsListCardMeta(textTheme)
                                  .copyWith(color: AppColors.textMuted),
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
                              style: AppTypography.eventsGroupedRowPrimary(textTheme),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppSpacing.xxs / 2),
                            Text(
                              timeRangeLabel,
                              style: AppTypography.eventsListCardMeta(textTheme),
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
