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
    final TextTheme textTheme = Theme.of(context).textTheme;
    final int current = event.participantCount;
    final int? max = event.maxParticipants;
    final double fillRatio = max != null && max > 0
        ? (current / max).clamp(0.0, 1.0)
        : 0.0;
    final bool isFull = max != null && current >= max;
    final Color statusColor = Color(event.status.colorValue);

    final String participantsLine = max != null && max > 0
        ? context.l10n.eventsOrganizerDashboardParticipants(
            current,
            max.toString(),
          )
        : context.l10n.eventsOrganizerDashboardParticipantsUnlimited(current);
    final bool isActiveLifecycle = event.status == EcoEventStatus.upcoming ||
        event.status == EcoEventStatus.inProgress;

    final StringBuffer sem = StringBuffer()
      ..write(event.title)
      ..write('. ')
      ..write(formatEventCalendarDate(context, event.date))
      ..write('. ')
      ..write(participantsLine);
    if (isActiveLifecycle) {
      if (!event.moderationApproved) {
        sem
          ..write('. ')
          ..write(context.l10n.eventsAwaitingModerationCta);
      } else {
        sem
          ..write('. ')
          ..write(context.l10n.eventsCheckInTitle);
        if (event.status == EcoEventStatus.inProgress) {
          sem
            ..write('. ')
            ..write(context.l10n.eventsOrganizerDashboardEvidenceAction);
        }
      }
    }
    final String semanticsLabel = sem.toString();

    return Semantics(
      button: true,
      label: semanticsLabel,
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      event.title,
                      style: AppTypography.eventsListCardTitle(textTheme).copyWith(
                        letterSpacing: -0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  if (event.isDeclined)
                    _ModerationPill(
                      label: context.l10n.eventsDeclinedDashboardPill,
                      color: AppColors.accentDanger,
                    )
                  else if (!event.moderationApproved)
                    _ModerationPill(
                      label: context.l10n.eventsPendingDashboardPill,
                      color: AppColors.warningAccent,
                    )
                  else
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
                    style: AppTypography.eventsListCardMeta(textTheme),
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
                      style: AppTypography.eventsListCardMeta(textTheme),
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
                                ? AppColors.warningAccent
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
                      style: AppTypography.eventsCaptionStrong(
                        textTheme,
                        color: isFull
                            ? AppColors.warningAccent
                            : AppColors.textSecondary,
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
                  style: AppTypography.eventsListCardMeta(textTheme),
                ),
              ],

              if (isActiveLifecycle) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                if (event.isDeclined)
                  Row(
                    children: <Widget>[
                      const Icon(
                        CupertinoIcons.xmark_circle,
                        size: 14,
                        color: AppColors.accentDanger,
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Expanded(
                        child: Text(
                          context.l10n.eventsDeclinedResubmitCta,
                          style: AppTypography.eventsListCardMeta(textTheme).copyWith(
                            color: AppColors.accentDanger,
                          ),
                        ),
                      ),
                    ],
                  )
                else if (!event.moderationApproved)
                  Row(
                    children: <Widget>[
                      const Icon(
                        CupertinoIcons.hourglass,
                        size: 14,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Expanded(
                        child: Text(
                          context.l10n.eventsAwaitingModerationCta,
                          style: AppTypography.eventsListCardMeta(textTheme),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: <Widget>[
                      _QuickActionButton(
                        icon: CupertinoIcons.qrcode_viewfinder,
                        label: context.l10n.eventsCheckInTitle,
                        onTap: onCheckIn,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      if (event.status == EcoEventStatus.inProgress)
                        _QuickActionButton(
                          icon: CupertinoIcons.camera,
                          label: context
                              .l10n.eventsOrganizerDashboardEvidenceAction,
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
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.localizedLabel(context.l10n),
        style: AppTypography.eventsCaptionStrong(
          textTheme,
          color: color,
        ).copyWith(fontSize: 11),
      ),
    );
  }
}

class _ModerationPill extends StatelessWidget {
  const _ModerationPill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: AppTypography.eventsCaptionStrong(
          textTheme,
          color: color,
        ).copyWith(fontSize: 11),
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
    final TextTheme textTheme = Theme.of(context).textTheme;
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
                    style: AppTypography.eventsCaptionStrong(
                      textTheme,
                      color: AppColors.primaryDark,
                    ).copyWith(fontSize: 12),
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
