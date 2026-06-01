import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_home/src/presentation/widgets/notifications/notification_tile.dart';
import 'package:feature_notifications/feature_notifications.dart';
import 'package:flutter/material.dart';

/// Collapsed / expandable stack row (iOS Notification Center style).
class NotificationGroupTile extends StatelessWidget {
  const NotificationGroupTile({
    super.key,
    required this.group,
    required this.expanded,
    required this.onToggleExpanded,
    required this.onOpenItem,
    this.onMarkGroupRead,
    this.onArchiveGroup,
  });

  final InboxNotificationGroup group;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final ValueChanged<UserNotification> onOpenItem;
  final VoidCallback? onMarkGroupRead;
  final VoidCallback? onArchiveGroup;

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = MediaQuery.of(context).disableAnimations;
    final Duration animDuration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 220);
    final UserNotification item = group.representative;
    final NotificationVisual visual = NotificationVisual.fromType(
      item.type,
      context,
    );
    final bool hasUnread = group.unreadCount > 0;
    final List<String> actorNames = group.topActors
        .map((a) => a.displayName)
        .where((String n) => n.isNotEmpty)
        .toList();
    final String summary = notificationGroupSummary(
      context.l10n,
      actorNames: actorNames,
      totalCount: group.isGrouped ? group.items.length : group.totalActorCount,
    );

    final Widget header = Material(
      color: hasUnread
          ? AppColors.primary.withValues(alpha: 0.04)
          : AppColors.panelBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radius18),
        side: BorderSide(
          color: hasUnread
              ? AppColors.primary.withValues(alpha: 0.18)
              : AppColors.divider,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: group.isGrouped ? onToggleExpanded : () => onOpenItem(item),
        borderRadius: BorderRadius.circular(AppSpacing.radius18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (group.topActors.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: NotificationActorAvatarStack(
                    actors: group.topActors,
                    overflowCount:
                        group.totalActorCount > group.topActors.length
                        ? group.totalActorCount - group.topActors.length
                        : 0,
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: visual.iconBackground,
                      borderRadius: AppRadii.circle,
                    ),
                    child: Icon(visual.icon, color: visual.iconColor, size: 20),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypographySurfaces.homeNotificationTileTitle(
                        Theme.of(context).textTheme,
                        unread: hasUnread,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.body,
                      maxLines: expanded ? 3 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypographySurfaces.homeNotificationTileBody(
                        Theme.of(context).textTheme,
                      ),
                    ),
                    if (group.isGrouped && !expanded) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(
                        item.type == UserNotificationType.eventChat
                            ? context.l10n.notificationsGroupMessageCount(
                                notificationDisplayCount(
                                  item,
                                  collapsedRows: group.items.length,
                                ),
                              )
                            : context.l10n.notificationsGroupSimilarCount(
                                group.items.length - 1,
                              ),
                        style:
                            AppTypographySurfaces.homeNotificationTileGroupCount(
                              Theme.of(context).textTheme,
                              color: visual.iconColor,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  if (hasUnread)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(bottom: AppSpacing.xxs),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryDark,
                        shape: BoxShape.circle,
                      ),
                    ),
                  Text(
                    notificationRelativeTime(context.l10n, group.latestAt),
                    style: AppTypographySurfaces.homeNotificationTileTimestamp(
                      Theme.of(context).textTheme,
                    ),
                  ),
                  if (group.isGrouped) ...<Widget>[
                    const SizedBox(height: 4),
                    Semantics(
                      button: true,
                      label: expanded
                          ? context.l10n.notificationsGroupCollapseHint
                          : context.l10n.notificationsGroupExpandHint,
                      child: IconButton(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                        onPressed: onToggleExpanded,
                        icon: AnimatedRotation(
                          turns: expanded ? 0.25 : 0,
                          duration: animDuration,
                          curve: AppMotion.standardCurve,
                          child: const Icon(
                            Icons.expand_more_rounded,
                            size: 22,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          button: group.isGrouped,
          expanded: group.isGrouped ? expanded : null,
          label: summary,
          hint: group.isGrouped
              ? (expanded
                    ? context.l10n.notificationsGroupCollapseHint
                    : context.l10n.notificationsGroupExpandHint)
              : null,
          child: header,
        ),
        AnimatedSize(
          duration: animDuration,
          curve: AppMotion.smooth,
          alignment: Alignment.topCenter,
          child: expanded && group.isGrouped
              ? Padding(
                  padding: const EdgeInsets.only(
                    left: AppSpacing.sm,
                    right: AppSpacing.sm,
                    top: AppSpacing.xs,
                  ),
                  child: Column(
                    children: <Widget>[
                      for (int i = 0; i < group.items.length; i++) ...<Widget>[
                        if (i > 0) const SizedBox(height: AppSpacing.xs),
                        NotificationTile(
                          item: group.items[i],
                          onTap: () => onOpenItem(group.items[i]),
                          groupCount: 1,
                        ),
                      ],
                      if (onMarkGroupRead != null && hasUnread)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: AppButton.text(
                            label: context.l10n.notificationsGroupMarkAllRead,
                            onPressed: onMarkGroupRead,
                            expand: false,
                          ),
                        ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
