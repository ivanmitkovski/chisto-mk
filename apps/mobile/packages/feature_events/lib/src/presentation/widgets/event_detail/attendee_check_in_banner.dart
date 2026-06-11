import 'dart:async';

import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_snack.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_auth/src/presentation/utils/auth_guard_ui.dart';
import 'package:feature_events/src/data/discovery_analytics.dart';
import 'package:feature_events/src/domain/models/eco_event.dart';
import 'package:feature_events/src/presentation/navigation/events_navigation.dart';
import 'package:feature_events/src/presentation/utils/events_localized_strings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AttendeeCheckInBanner extends ConsumerWidget {
  const AttendeeCheckInBanner({super.key, required this.event});

  final EcoEvent event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final l10n = context.l10n;

    return Semantics(
      button: true,
      label: l10n.eventsAttendeeCheckInSemantic,
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: () async {
            if (event.isCheckedIn) {
              AppSnack.show(
                context,
                message: l10n.eventsAttendeeAlreadyCheckedInSnack,
                type: AppSnackType.success,
              );
              return;
            }
            if (!event.canOpenAttendeeCheckIn) {
              AppSnack.show(
                context,
                message: l10n.eventsAttendeeCheckInPausedSnack,
                type: AppSnackType.warning,
              );
              return;
            }
            if (!await ensureLocationEligibleForAction(context, ref)) {
              return;
            }
            if (!context.mounted) {
              return;
            }
            final bool? success = await EventsNavigation.openAttendeeQrScanner(
              context,
              eventId: event.id,
            );
            if (!context.mounted || success != true) {
              return;
            }
            unawaited(
              DiscoveryAnalytics.instance.maybeTrack(
                DiscoveryFunnelStep.checkInSuccess,
                eventId: event.id,
              ),
            );
            AppSnack.show(
              context,
              message: l10n.eventsAttendeeCheckInCompleteSnack,
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
                        event.isCheckedIn
                            ? l10n.eventsAttendeeBannerTitleCheckedIn
                            : l10n.eventsAttendeeBannerTitleInProgress,
                        style: AppTypography.eventsCalloutTitle(textTheme),
                      ),
                      const SizedBox(height: AppSpacing.xxs / 2),
                      Text(
                        event.isCheckedIn
                            ? (event.attendeeCheckedInAt == null
                                  ? l10n.eventsAttendeeBannerSubtitleAttendanceConfirmed
                                  : l10n.eventsAttendeeBannerSubtitleCheckedInAt(
                                      formatCheckInTime(
                                        event.attendeeCheckedInAt!,
                                      ),
                                    ))
                            : (event.canOpenAttendeeCheckIn
                                  ? l10n.eventsAttendeeBannerSubtitleScanQr
                                  : l10n.eventsAttendeeBannerSubtitlePaused),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.eventsCalloutSubtitle(textTheme),
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
