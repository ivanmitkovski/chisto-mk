import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';

class ReminderSection extends StatelessWidget {
  const ReminderSection({
    super.key,
    required this.event,
    required this.onToggleReminder,
  });

  final EcoEvent event;
  final VoidCallback onToggleReminder;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.bell_fill,
              size: 18,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Event reminder',
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  event.reminderEnabled
                      ? (event.reminderAt == null
                          ? 'Reminder is on'
                          : 'Set for ${event.reminderAt!.hour.toString().padLeft(2, '0')}:${event.reminderAt!.minute.toString().padLeft(2, '0')}')
                      : 'Get notified before event starts',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          CupertinoButton(
            onPressed: onToggleReminder,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.radius10, vertical: AppSpacing.xxs),
            minimumSize: Size.zero,
            child: Text(
              event.reminderEnabled ? 'Disable' : 'Enable',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
