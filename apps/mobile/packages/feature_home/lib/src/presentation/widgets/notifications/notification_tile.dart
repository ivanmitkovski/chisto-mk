import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_home/src/presentation/widgets/notifications/notification_preview_text.dart';
import 'package:feature_notifications/feature_notifications.dart';
import 'package:flutter/material.dart';

class NotificationVisual {
  const NotificationVisual({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.label,
  });

  factory NotificationVisual.fromType(
    UserNotificationType type,
    BuildContext context,
  ) {
    final l10n = context.l10n;
    switch (type) {
      case UserNotificationType.siteUpdate:
        return NotificationVisual(
          icon: Icons.place_rounded,
          iconColor: AppColors.primaryDark,
          iconBackground: AppColors.primary.withValues(alpha: 0.12),
          label: l10n.notificationsTypeSiteUpdates,
        );
      case UserNotificationType.reportStatus:
        return NotificationVisual(
          icon: Icons.assignment_rounded,
          iconColor: AppColors.notificationReport,
          iconBackground: AppColors.notificationReport.withValues(alpha: 0.12),
          label: l10n.notificationsTypeReportStatus,
        );
      case UserNotificationType.upvote:
        return NotificationVisual(
          icon: Icons.favorite_rounded,
          iconColor: AppColors.notificationUpvote,
          iconBackground: AppColors.notificationUpvote.withValues(alpha: 0.12),
          label: l10n.notificationsTypeUpvotes,
        );
      case UserNotificationType.comment:
        return NotificationVisual(
          icon: Icons.chat_bubble_rounded,
          iconColor: AppColors.notificationComment,
          iconBackground: AppColors.notificationComment.withValues(alpha: 0.12),
          label: l10n.notificationsTypeComments,
        );
      case UserNotificationType.nearbyReport:
        return NotificationVisual(
          icon: Icons.radar_rounded,
          iconColor: AppColors.notificationNearby,
          iconBackground: AppColors.notificationNearby.withValues(alpha: 0.12),
          label: l10n.notificationsTypeNearbyReports,
        );
      case UserNotificationType.cleanupEvent:
        return NotificationVisual(
          icon: Icons.event_rounded,
          iconColor: AppColors.primaryDark,
          iconBackground: AppColors.primary.withValues(alpha: 0.14),
          label: l10n.notificationsTypeCleanupEvents,
        );
      case UserNotificationType.eventChat:
        return NotificationVisual(
          icon: Icons.forum_rounded,
          iconColor: AppColors.notificationChat,
          iconBackground: AppColors.notificationChat.withValues(alpha: 0.12),
          label: l10n.notificationsTypeEventChat,
        );
      case UserNotificationType.system:
        return NotificationVisual(
          icon: Icons.shield_outlined,
          iconColor: AppColors.textMuted,
          iconBackground: AppColors.inputFill,
          label: l10n.notificationsTypeSystem,
        );
      case UserNotificationType.achievement:
        return NotificationVisual(
          icon: Icons.emoji_events_rounded,
          iconColor: AppColors.notificationAchievement,
          iconBackground: AppColors.notificationAchievement.withValues(
            alpha: 0.12,
          ),
          label: l10n.notificationsTypeSystem,
        );
      case UserNotificationType.welcome:
        return NotificationVisual(
          icon: Icons.waving_hand_rounded,
          iconColor: AppColors.primaryDark,
          iconBackground: AppColors.primary.withValues(alpha: 0.12),
          label: l10n.notificationsTypeSystem,
        );
    }
  }

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String label;
}

class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.item,
    required this.onTap,
    this.groupCount = 1,
    this.borderRadius,
  });

  final UserNotification item;
  final VoidCallback onTap;
  final int groupCount;

  /// When swiping, pass a radius with square corners on the revealed edge.
  final BorderRadius? borderRadius;

  BorderRadius get _shapeRadius =>
      borderRadius ?? BorderRadius.circular(AppSpacing.radius18);

  @override
  Widget build(BuildContext context) {
    final NotificationVisual visual = NotificationVisual.fromType(
      item.type,
      context,
    );
    final bool hasTarget = item.targetSiteId != null;
    final String readState = item.isRead
        ? context.l10n.notificationsSemanticReadState
        : context.l10n.notificationsSemanticUnreadState;
    final String semanticLabel =
        '${context.l10n.notificationsTileSemanticLabel(readState, visual.label, item.title)}. ${item.body}';
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      label: semanticLabel,
      hint: hasTarget ? context.l10n.notificationsTileOpenRelatedHint : null,
      child: Material(
        color: item.isRead
            ? AppColors.panelBackground
            : AppColors.primary.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: _shapeRadius,
          side: BorderSide(
            color: item.isRead
                ? AppColors.divider
                : AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: _shapeRadius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: NotificationInboxRowLayout(
              showNavigationChevron: hasTarget,
              timestamp: notificationRelativeTime(context.l10n, item.createdAt),
              leading: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: visual.iconBackground,
                  borderRadius: BorderRadius.circular(AppSpacing.radius10),
                ),
                child: Icon(visual.icon, size: 18, color: visual.iconColor),
              ),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  NotificationTileMetaRow(
                    badge: NotificationTypeBadge(
                      label: visual.label,
                      backgroundColor: visual.iconBackground,
                      labelColor: visual.iconColor,
                    ),
                    showUnreadDot: !item.isRead,
                  ),
                  const SizedBox(height: 6),
                  NotificationPreviewText(
                    text: item.title,
                    maxLines: notificationTitleMaxLines,
                    style: AppTypographySurfaces.homeNotificationTileTitle(
                      textTheme,
                      unread: !item.isRead,
                    ),
                  ),
                  if (groupCount > 1) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      item.type == UserNotificationType.eventChat
                          ? context.l10n.notificationsGroupMessageCount(
                              groupCount,
                            )
                          : context.l10n.notificationsGroupSimilarCount(
                              groupCount - 1,
                            ),
                      style: textTheme.bodySmall?.copyWith(
                        color: visual.iconColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  NotificationPreviewText(
                    text: item.body,
                    maxLines: notificationBodyMaxLines(context),
                    style: AppTypographySurfaces.homeNotificationTileBody(
                      textTheme,
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
