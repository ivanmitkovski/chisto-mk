import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/navigation/events_navigation.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';

class AttendeeCheckInBanner extends StatelessWidget {
  const AttendeeCheckInBanner({super.key, required this.event});

  final EcoEvent event;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      label: 'Scan to check in at event',
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: () async {
            if (event.isCheckedIn) {
              AppSnack.show(
                context,
                message: 'You are already checked in.',
                type: AppSnackType.success,
              );
              return;
            }
            if (!event.canOpenAttendeeCheckIn) {
              AppSnack.show(
                context,
                message: 'Organizer has paused check-in for now.',
                type: AppSnackType.warning,
              );
              return;
            }
            AppHaptics.softTransition();
            final bool? success = await EventsNavigation.openAttendeeQrScanner(
              context,
              eventId: event.id,
            );
            if (!context.mounted || success != true) {
              return;
            }
            AppSnack.show(
              context,
              message: 'Check-in complete.',
              type: AppSnackType.success,
            );
          },
          borderRadius: BorderRadius.circular(AppSpacing.radius14),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppSpacing.radius14),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: AppSpacing.avatarMd,
                  height: AppSpacing.avatarMd,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: const Icon(
                    CupertinoIcons.qrcode_viewfinder,
                    size: 24,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        event.isCheckedIn ? 'You are checked in' : 'Event is in progress',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs / 2),
                      Text(
                        event.isCheckedIn
                            ? (event.attendeeCheckedInAt == null
                                ? 'Attendance confirmed'
                                : 'Checked in at '
                                    '${event.attendeeCheckedInAt!.hour.toString().padLeft(2, '0')}:'
                                    '${event.attendeeCheckedInAt!.minute.toString().padLeft(2, '0')}')
                            : (event.canOpenAttendeeCheckIn
                                ? 'Scan the organizer\'s QR to check in'
                                : 'Check-in is temporarily paused'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  event.isCheckedIn
                      ? CupertinoIcons.checkmark_circle_fill
                      : CupertinoIcons.chevron_right,
                  size: 18,
                  color: event.isCheckedIn
                      ? AppColors.primaryDark
                      : AppColors.primaryDark.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
