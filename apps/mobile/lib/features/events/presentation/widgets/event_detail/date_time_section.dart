import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/utils/event_calendar_date_format.dart';
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

    return Semantics(
      button: true,
      label: context.l10n.eventsDateInfoSemantic(
        formatEventCalendarDate(context, event.date),
        event.formattedTimeRange,
      ),
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: () => _showDateInfo(context),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: embeddedInGroupedPanel
              // ── Embedded: simple icon row, no card chrome ─────────────────
              ? ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 52),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        CupertinoIcons.calendar,
                        size: AppSpacing.iconMd,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              formatEventCalendarDate(context, event.date),
                              style: AppTypography.eventsGroupedRowPrimary(textTheme),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              event.formattedTimeRange,
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
                )
              // ── Standalone: prominent card with large icon ─────────────────
              : Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.panelBackground,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
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
                              formatEventCalendarDate(context, event.date),
                              style: AppTypography.eventsGroupedRowPrimary(textTheme),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppSpacing.xxs / 2),
                            Text(
                              event.formattedTimeRange,
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
