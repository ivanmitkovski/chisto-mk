import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/shared/widgets/primary_button.dart';

class StickyBottomCTA extends StatelessWidget {
  const StickyBottomCTA({
    super.key,
    required this.event,
    required this.onToggleJoin,
    required this.onToggleReminder,
    required this.onStartEvent,
    required this.onManageCheckIn,
    required this.onOpenAttendeeCheckIn,
    required this.onOpenCleanupEvidence,
  });

  final EcoEvent event;
  final VoidCallback onToggleJoin;
  final VoidCallback onToggleReminder;
  final VoidCallback onStartEvent;
  final VoidCallback onManageCheckIn;
  final VoidCallback onOpenAttendeeCheckIn;
  final VoidCallback onOpenCleanupEvidence;

  @override
  Widget build(BuildContext context) {
    final double bottomSafe = MediaQuery.of(context).padding.bottom;

    final String label;
    final bool enabled;
    final VoidCallback? onPressed;
    String? secondaryLabel;
    VoidCallback? onSecondaryPressed;

    if (event.isOrganizer) {
      if (event.status == EcoEventStatus.upcoming) {
        label = 'Start event';
        enabled = true;
        onPressed = onStartEvent;
      } else if (event.status == EcoEventStatus.inProgress) {
        label = 'Manage check-in';
        enabled = true;
        onPressed = onManageCheckIn;
      } else if (event.status == EcoEventStatus.completed) {
        label = event.hasAfterImages ? 'Edit after photos' : 'Upload after photos';
        enabled = true;
        onPressed = onOpenCleanupEvidence;
      } else {
        label = event.status.label;
        enabled = false;
        onPressed = null;
      }
    } else if (event.status == EcoEventStatus.inProgress && event.isJoined) {
      if (event.isCheckedIn) {
        label = 'Checked in';
        enabled = false;
        onPressed = null;
      } else if (event.canOpenAttendeeCheckIn) {
        label = 'Scan to check in';
        enabled = true;
        onPressed = onOpenAttendeeCheckIn;
      } else {
        label = 'Check-in paused';
        enabled = false;
        onPressed = null;
      }
    } else if (event.isJoined) {
      label = event.reminderEnabled ? 'Turn reminder off' : 'Set reminder';
      enabled = true;
      onPressed = onToggleReminder;
      secondaryLabel = 'Leave event';
      onSecondaryPressed = onToggleJoin;
    } else if (!event.isJoinable) {
      label = event.status.label;
      enabled = false;
      onPressed = null;
    } else {
      label = 'Join eco action';
      enabled = true;
      onPressed = onToggleJoin;
    }

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.md + bottomSafe,
        ),
        decoration: BoxDecoration(
          color: AppColors.panelBackground,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: secondaryLabel == null
            ? PrimaryButton(
                label: label,
                enabled: enabled,
                onPressed: enabled ? (onPressed ?? onToggleJoin) : null,
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  PrimaryButton(
                    label: label,
                    enabled: enabled,
                    onPressed: enabled ? onPressed : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: OutlinedButton(
                      onPressed: onSecondaryPressed,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.divider),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Text(
                        secondaryLabel,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
