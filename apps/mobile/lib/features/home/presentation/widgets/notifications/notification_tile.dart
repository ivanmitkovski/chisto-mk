import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/notifications/domain/models/user_notification.dart';

class NotificationVisual {
  const NotificationVisual({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String label;

  factory NotificationVisual.fromType(UserNotificationType type) {
    switch (type) {
      case UserNotificationType.siteUpdate:
        return NotificationVisual(
          icon: Icons.place_rounded,
          iconColor: AppColors.primaryDark,
          iconBackground: AppColors.primary.withValues(alpha: 0.12),
          label: 'Site update',
        );
      case UserNotificationType.reportStatus:
        return NotificationVisual(
          icon: Icons.assignment_rounded,
          iconColor: const Color(0xFF1976D2),
          iconBackground: const Color(0xFF1976D2).withValues(alpha: 0.12),
          label: 'Report',
        );
      case UserNotificationType.upvote:
        return NotificationVisual(
          icon: Icons.favorite_rounded,
          iconColor: const Color(0xFFE91E63),
          iconBackground: const Color(0xFFE91E63).withValues(alpha: 0.12),
          label: 'Upvote',
        );
      case UserNotificationType.comment:
        return NotificationVisual(
          icon: Icons.chat_bubble_rounded,
          iconColor: const Color(0xFF7B1FA2),
          iconBackground: const Color(0xFF7B1FA2).withValues(alpha: 0.12),
          label: 'Comment',
        );
      case UserNotificationType.nearbyReport:
        return NotificationVisual(
          icon: Icons.radar_rounded,
          iconColor: const Color(0xFFE65100),
          iconBackground: const Color(0xFFE65100).withValues(alpha: 0.12),
          label: 'Nearby',
        );
      case UserNotificationType.cleanupEvent:
        return NotificationVisual(
          icon: Icons.event_rounded,
          iconColor: AppColors.primaryDark,
          iconBackground: AppColors.primary.withValues(alpha: 0.14),
          label: 'Event',
        );
      case UserNotificationType.eventChat:
        return NotificationVisual(
          icon: Icons.forum_rounded,
          iconColor: const Color(0xFF00897B),
          iconBackground: const Color(0xFF00897B).withValues(alpha: 0.12),
          label: 'Chat',
        );
      case UserNotificationType.system:
        return const NotificationVisual(
          icon: Icons.shield_outlined,
          iconColor: AppColors.textMuted,
          iconBackground: AppColors.inputFill,
          label: 'System',
        );
      case UserNotificationType.achievement:
        return NotificationVisual(
          icon: Icons.emoji_events_rounded,
          iconColor: const Color(0xFFF9A825),
          iconBackground: const Color(0xFFF9A825).withValues(alpha: 0.12),
          label: 'Achievement',
        );
      case UserNotificationType.welcome:
        return NotificationVisual(
          icon: Icons.waving_hand_rounded,
          iconColor: AppColors.primaryDark,
          iconBackground: AppColors.primary.withValues(alpha: 0.12),
          label: 'Welcome',
        );
    }
  }
}

class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.item,
    required this.onTap,
    this.groupCount = 1,
  });

  final UserNotification item;
  final VoidCallback onTap;
  final int groupCount;

  @override
  Widget build(BuildContext context) {
    final NotificationVisual visual = NotificationVisual.fromType(item.type);
    final bool hasTarget = item.targetSiteId != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Semantics(
        button: true,
        label:
            '${item.isRead ? 'Read' : 'Unread'} ${visual.label} notification: ${item.title}',
        hint: hasTarget ? 'Opens related content' : null,
        child: Material(
          color: AppColors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppSpacing.radius18),
            onTap: onTap,
            child: Ink(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: item.isRead
                    ? AppColors.panelBackground
                    : AppColors.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(AppSpacing.radius18),
                border: Border.all(
                  color: item.isRead
                      ? AppColors.divider
                      : AppColors.primary.withValues(alpha: 0.2),
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.shadowLight,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: visual.iconBackground,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(visual.icon, size: 18, color: visual.iconColor),
                      ),
                    ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: visual.iconBackground,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            visual.label,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: visual.iconColor,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                  height: 1.1,
                                ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: item.isRead
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                                height: 1.2,
                              ),
                        ),
                        const SizedBox(height: 4),
                        if (groupCount > 1)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              'and ${groupCount - 1} similar',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: visual.iconColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                            ),
                          ),
                        Text(
                          item.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.25,
                              ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: hasTarget ? 44 : 52,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: <Widget>[
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              if (!item.isRead) ...<Widget>[
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primaryDark,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                _relativeTime(item.createdAt),
                                textAlign: TextAlign.right,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppColors.textMuted,
                                      fontSize: 12,
                                      height: 1.15,
                                      fontFeatures: const <FontFeature>[
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                              ),
                            ],
                          ),
                        ),
                        if (hasTarget)
                          const Center(
                            child: Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                              color: AppColors.textMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _relativeTime(DateTime value) {
    final Duration diff = DateTime.now().difference(value);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}';
  }
}
