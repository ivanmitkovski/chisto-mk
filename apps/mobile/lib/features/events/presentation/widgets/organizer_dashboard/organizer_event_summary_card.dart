import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/utils/event_calendar_date_format.dart';
import 'package:chisto_mobile/features/events/presentation/utils/events_localized_strings.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

/// Compact card for an organizer's event in the dashboard list.
///
/// Shows: title, date, participant count progress bar, status pill,
/// and quick-action buttons for check-in and cleanup evidence.
class OrganizerEventSummaryCard extends StatelessWidget {
  const OrganizerEventSummaryCard({
    super.key,
    required this.event,
    required this.onTap,
    required this.onCheckIn,
    required this.onEvidence,
  });

  final EcoEvent event;
  final VoidCallback onTap;
  final VoidCallback onCheckIn;
  final VoidCallback onEvidence;

  @override
  Widget build(BuildContext context) {
    final int current = event.participantCount;
    final int? max = event.maxParticipants;
    final double fillRatio = max != null && max > 0
        ? (current / max).clamp(0.0, 1.0)
        : 0.0;
    final bool isFull = max != null && current >= max;
    final Color statusColor = Color(event.status.colorValue);

    return Semantics(
      button: true,
      label: event.title,
      child: GestureDetector(
        onTap: () {
          AppHaptics.tap();
          onTap();
        },
        child: Container(
          margin: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xs,
          ),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.panelBackground,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.divider.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Title + status pill row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      event.title,
                      style: AppTypography.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _StatusPill(status: event.status, color: statusColor),
                ],
              ),

              const SizedBox(height: AppSpacing.xs),

              // Date + site
              Row(
                children: <Widget>[
                  const Icon(
                    CupertinoIcons.calendar,
                    size: 13,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  Text(
                    formatEventCalendarDate(context, event.date),
                    style: AppTypography.textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(
                    CupertinoIcons.location,
                    size: 13,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: AppSpacing.xxs),
                  Expanded(
                    child: Text(
                      event.siteName,
                      style: AppTypography.textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              if (max != null) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                // Participant progress bar
                Row(
                  children: <Widget>[
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: fillRatio,
                          minHeight: 4,
                          backgroundColor: AppColors.divider.withValues(
                            alpha: 0.5,
                          ),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isFull
                                ? const Color(0xFFF5A623)
                                : AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      context.l10n.eventsOrganizerDashboardParticipants(
                        current,
                        max.toString(),
                      ),
                      style: AppTypography.textTheme.labelSmall?.copyWith(
                        color: isFull
                            ? const Color(0xFFF5A623)
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ] else ...<Widget>[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  context.l10n.eventsOrganizerDashboardParticipantsUnlimited(
                    current,
                  ),
                  style: AppTypography.textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],

              // Quick-action buttons (only for active events)
              if (event.status == EcoEventStatus.upcoming ||
                  event.status == EcoEventStatus.inProgress) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: <Widget>[
                    _QuickActionButton(
                      icon: CupertinoIcons.qrcode_viewfinder,
                      label: context.l10n.eventsCheckInTitle,
                      onTap: onCheckIn,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    if (event.status == EcoEventStatus.inProgress ||
                        event.status == EcoEventStatus.completed)
                      _QuickActionButton(
                        icon: CupertinoIcons.camera,
                        label:
                            context.l10n.eventsOrganizerDashboardEvidenceAction,
                        onTap: onEvidence,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, required this.color});
  final EcoEventStatus status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.localizedLabel(context.l10n),
        style: AppTypography.textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: AppSpacing.avatarMd,
          minHeight: AppSpacing.avatarMd,
        ),
        child: Material(
          color: AppColors.transparent,
          child: InkWell(
            onTap: () {
              AppHaptics.tap();
              onTap();
            },
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(icon, size: 14, color: AppColors.primaryDark),
                  const SizedBox(width: AppSpacing.xxs),
                  Text(
                    label,
                    style: AppTypography.textTheme.labelSmall?.copyWith(
                      color: AppColors.primaryDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
