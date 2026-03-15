import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/widgets/event_detail/custom_reminder_datetime_sheet.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

class ReminderPickerSheet {
  ReminderPickerSheet._();

  static const List<({String label, Duration before})> _presets = <({String label, Duration before})>[
    (label: '1 day before', before: Duration(days: 1)),
    (label: '3 hours before', before: Duration(hours: 3)),
    (label: '1 hour before', before: Duration(hours: 1)),
    (label: '30 minutes before', before: Duration(minutes: 30)),
  ];

  static String formatReminderLabel(DateTime dateTime) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(dateTime.day)}/${two(dateTime.month)} '
        '${two(dateTime.hour)}:${two(dateTime.minute)}';
  }

  static Future<DateTime?> show(BuildContext context, EcoEvent event) {
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.panelBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusSheet)),
      ),
      builder: (BuildContext sheetContext) {
        return _ReminderPickerContent(
          event: event,
          presets: _presets,
        );
      },
    );
  }
}

class _ReminderPickerContent extends StatelessWidget {
  const _ReminderPickerContent({
    required this.event,
    required this.presets,
  });

  final EcoEvent event;
  final List<({String label, Duration before})> presets;

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final DateTime start = event.startDateTime;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Center(
              child: Container(
                width: AppSpacing.sheetHandle,
                height: AppSpacing.sheetHandleHeight,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(AppSpacing.sheetHandleHeight / 2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Choose reminder time',
              style: AppTypography.sheetTitle,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Event starts at ${event.formattedTimeRange} on ${event.formattedDate}.',
              style: AppTypography.cardSubtitle,
            ),
            const SizedBox(height: AppSpacing.lg),
            ...presets.map((({Duration before, String label}) preset) {
              final DateTime candidate = start.subtract(preset.before);
              final bool enabled = candidate.isAfter(now);
              return _ReminderOptionTile(
                label: preset.label,
                subtitle: enabled
                    ? ReminderPickerSheet.formatReminderLabel(candidate)
                    : 'Unavailable for this event time',
                enabled: enabled,
                onTap: enabled
                    ? () {
                        AppHaptics.tap();
                        Navigator.of(context).pop(candidate);
                      }
                    : null,
              );
            }),
            const SizedBox(height: AppSpacing.sm),
            _ReminderOptionTile(
              label: 'Custom date and time',
              subtitle: 'Pick a specific reminder moment',
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
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
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
      ),
    );
  }
}
