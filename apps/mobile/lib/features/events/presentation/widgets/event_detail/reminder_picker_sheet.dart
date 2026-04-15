import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/utils/event_calendar_date_format.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/custom_reminder_datetime_sheet.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

class ReminderPickerSheet {
  ReminderPickerSheet._();

  static String formatReminderLabel(DateTime dateTime) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(dateTime.day)}/${two(dateTime.month)} '
        '${two(dateTime.hour)}:${two(dateTime.minute)}';
  }

  static Future<DateTime?> show(BuildContext context, EcoEvent event) {
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (BuildContext sheetContext) {
        return _ReminderPickerContent(event: event);
      },
    );
  }
}

class _ReminderPickerContent extends StatelessWidget {
  const _ReminderPickerContent({required this.event});

  final EcoEvent event;

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final DateTime start = event.startDateTime;
    final List<({Duration before, String label})> presets =
        <({Duration before, String label})>[
      (before: const Duration(days: 1), label: context.l10n.eventsReminderPreset1Day),
      (before: const Duration(hours: 3), label: context.l10n.eventsReminderPreset3Hours),
      (before: const Duration(hours: 1), label: context.l10n.eventsReminderPreset1Hour),
      (before: const Duration(minutes: 30), label: context.l10n.eventsReminderPreset30Mins),
    ];

    return ReportSheetScaffold(
      title: context.l10n.eventsReminderSheetTitle,
      subtitle: context.l10n.eventsReminderSheetSubtitle(
        event.formattedTimeRange,
        formatEventCalendarDate(context, event.date),
      ),
      fitToContent: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ...presets.map((({Duration before, String label}) preset) {
            final DateTime candidate = start.subtract(preset.before);
            final bool enabled = candidate.isAfter(now);
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _ReminderOptionTile(
                label: preset.label,
                subtitle: enabled
                    ? ReminderPickerSheet.formatReminderLabel(candidate)
                    : context.l10n.eventsReminderUnavailableSubtitle,
                enabled: enabled,
                onTap: enabled
                    ? () {
                        AppHaptics.tap();
                        Navigator.of(context).pop(candidate);
                      }
                    : null,
              ),
            );
          }),
          _ReminderOptionTile(
            label: context.l10n.eventsReminderCustomTitle,
            subtitle: context.l10n.eventsReminderCustomSubtitle,
            enabled: true,
            icon: CupertinoIcons.calendar_badge_plus,
            onTap: () async {
              AppHaptics.tap();
              final DateTime? custom = await CustomReminderDateTimeSheet.show(
                context: context,
                eventStart: start,
              );
              if (!context.mounted || custom == null) {
                return;
              }
              Navigator.of(context).pop(custom);
            },
          ),
        ],
      ),
    );
  }
}

class _ReminderOptionTile extends StatelessWidget {
  const _ReminderOptionTile({
    required this.label,
    required this.subtitle,
    required this.enabled,
    required this.onTap,
    this.icon,
  });

  final String label;
  final String subtitle;
  final bool enabled;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: enabled ? AppColors.inputFill : AppColors.inputFill.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: enabled ? AppColors.divider : AppColors.divider.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon!, size: AppSpacing.iconMd, color: enabled ? AppColors.primary : AppColors.textMuted),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      label,
                      style: AppTypography.cardTitle.copyWith(
                        color: enabled ? AppColors.textPrimary : AppColors.textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      subtitle,
                      style: AppTypography.cardSubtitle.copyWith(
                        fontSize: 13,
                        color: enabled ? AppColors.textMuted : AppColors.textMuted.withValues(alpha: 0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  CupertinoIcons.chevron_right,
                  size: AppSpacing.iconSm,
                  color: enabled ? AppColors.textMuted : AppColors.textMuted.withValues(alpha: 0.5),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
