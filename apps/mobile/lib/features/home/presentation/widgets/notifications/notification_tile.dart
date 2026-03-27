import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/home/domain/models/feed_notification.dart';

class NotificationVisual {
  const NotificationVisual({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;

  factory NotificationVisual.fromType(FeedNotificationType type) {
    switch (type) {
      case FeedNotificationType.update:
        return NotificationVisual(
          icon: Icons.campaign_rounded,
          iconColor: AppColors.textPrimary,
          iconBackground: AppColors.inputFill,
        );
      case FeedNotificationType.action:
        return NotificationVisual(
          icon: Icons.volunteer_activism_rounded,
          iconColor: AppColors.primaryDark,
          iconBackground: AppColors.primary.withValues(alpha: 0.14),
        );
      case FeedNotificationType.system:
        return const NotificationVisual(
          icon: Icons.shield_outlined,
          iconColor: AppColors.textMuted,
          iconBackground: AppColors.inputFill,
        );
    }
  }
}

class NotificationTile extends StatelessWidget {
  const NotificationTile({super.key, required this.item, required this.onTap});

  final FeedNotification item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final NotificationVisual visual = NotificationVisual.fromType(item.type);
    final bool canOpenTarget = item.targetSiteId != null;
    final String typeLabel = switch (item.type) {
      FeedNotificationType.update => 'Update',
      FeedNotificationType.action => 'Action',
      FeedNotificationType.system => 'System',
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Semantics(
        button: true,
        label:
            '${item.isRead ? 'Read' : 'Unread'} $typeLabel notification: ${item.title}',
        hint: canOpenTarget ? 'Opens related content' : 'Notification details',
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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: visual.iconBackground,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(visual.icon, size: 18, color: visual.iconColor),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
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
                                typeLabel,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: visual.iconColor,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                      height: 1.1,
                                    ),
                              ),
                            ),
                          ],
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
                        Text(
                          item.message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.textSecondary,
                                height: 1.25,
                              ),
                        ),
                        if (canOpenTarget) ...<Widget>[
                          const SizedBox(height: 6),
                          Row(
                            children: <Widget>[
                              const Icon(
                                Icons.open_in_new_rounded,
                                size: 12,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                item.targetTabIndex == 1
                                    ? 'Opens cleaning events'
                                    : 'Opens pollution site',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: AppColors.textMuted,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 6),
                        Text(
                          _relativeTime(item.createdAt),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      if (!item.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryDark,
                            shape: BoxShape.circle,
                          ),
                        )
                      else
                        const SizedBox(width: 8, height: 8),
                      const SizedBox(height: 8),
                      Text(
                        item.isRead ? 'Read' : 'Unread',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: item.isRead
                              ? AppColors.textMuted
                              : AppColors.accentDanger,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                      if (canOpenTarget) ...<Widget>[
                        const SizedBox(height: 4),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: AppColors.textMuted,
                        ),
                      ],
                    ],
                  ),
                ],
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
