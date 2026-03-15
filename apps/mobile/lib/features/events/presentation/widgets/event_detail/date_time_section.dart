import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

class DateTimeSection extends StatelessWidget {
  const DateTimeSection({
    super.key,
    required this.event,
    required this.onExportCalendar,
  });

  final EcoEvent event;
  final VoidCallback onExportCalendar;

  void _showDateInfo(BuildContext context) {
    AppHaptics.tap();
    final Duration diff = event.startDateTime.difference(DateTime.now());
    final String relative;
    if (diff.isNegative) {
      final int daysAgo = diff.inDays.abs();
      relative = daysAgo == 0 ? 'Earlier today' : '$daysAgo day${daysAgo == 1 ? '' : 's'} ago';
    } else if (diff.inDays == 0) {
      relative = 'Today';
    } else if (diff.inDays == 1) {
      relative = 'Tomorrow';
    } else {
      relative = 'In ${diff.inDays} days';
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.panelBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: AppSpacing.sheetHandle,
                  height: AppSpacing.sheetHandleHeight,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  ),
                  child: const Icon(CupertinoIcons.calendar, size: 28, color: AppColors.primaryDark),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  event.formattedDate,
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${event.formattedTimeRange}  ·  $relative',
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
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
                    icon: const Icon(CupertinoIcons.calendar_badge_plus, size: 18),
                    label: const Text('Add to calendar'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.divider),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radius14)),
                      foregroundColor: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
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
      label: '${event.formattedDate}, ${event.formattedTimeRange}',
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: () => _showDateInfo(context),
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          child: Container(
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
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: const Icon(CupertinoIcons.calendar, size: 22, color: AppColors.primaryDark),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        event.formattedDate,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs / 2),
                      Text(
                        event.formattedTimeRange,
                        style: textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 14,
                  color: AppColors.textMuted.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
