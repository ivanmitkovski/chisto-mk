part of 'package:feature_notifications/src/presentation/notifications_inbox/notifications_inbox_screen.dart';

extension _NotificationsInboxListBuild on _NotificationsScreenState {
  void _appendInboxContentSlivers(
    List<Widget> slivers, {
    required int animationIndexStart,
  }) {
    int animationIndex = animationIndexStart;
    for (int dayIndex = 0; dayIndex < _daySections.length; dayIndex++) {
      final InboxDaySection day = _daySections[dayIndex];
      slivers.add(
        SliverToBoxAdapter(
          child: NotificationDaySectionHeader(
            title: day.title,
            isFirst: dayIndex == 0,
          ),
        ),
      );
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((
              BuildContext context,
              int index,
            ) {
              final InboxNotificationGroup group = day.groups[index];
              if (group.isGrouped) {
                return _buildAnimatedGroupRow(group, animationIndex + index);
              }
              return _buildAnimatedNotificationRow(
                group.representative,
                animationIndex + index,
              );
            }, childCount: day.groups.length),
          ),
        ),
      );
      animationIndex += day.groups.length;
    }
  }

  Widget _buildAnimatedGroupRow(InboxNotificationGroup group, int index) {
    final double stagger = (index * 0.06).clamp(0.0, 0.5);
    final Animation<double> fade = CurvedAnimation(
      parent: _entranceController,
      curve: Interval(
        stagger,
        (stagger + 0.45).clamp(0.0, 1.0),
        curve: AppMotion.standardCurve,
      ),
    );
    final Animation<Offset> slide =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Interval(
              stagger,
              (stagger + 0.45).clamp(0.0, 1.0),
              curve: AppMotion.emphasized,
            ),
          ),
        );
    final bool expanded = _isGroupExpanded(group);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: FadeTransition(
        opacity: fade,
        child: SlideTransition(
          position: slide,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radius18),
            clipBehavior: Clip.antiAliasWithSaveLayer,
            child: NotificationGroupTile(
              key: ValueKey<String>(
                'notification-group-${_expandedKey(group)}',
              ),
              group: group,
              expanded: expanded,
              onToggleExpanded: () => _toggleGroupExpanded(group),
              onOpenItem: _openNotification,
              onMarkGroupRead: group.unreadCount > 0
                  ? () => _markGroupRead(group)
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedNotificationRow(
    UserNotification item,
    int index, {
    int groupCount = 1,
  }) {
    final double stagger = (index * 0.06).clamp(0.0, 0.5);
    final Animation<double> fade = CurvedAnimation(
      parent: _entranceController,
      curve: Interval(
        stagger,
        (stagger + 0.45).clamp(0.0, 1.0),
        curve: AppMotion.standardCurve,
      ),
    );
    final Animation<Offset> slide =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _entranceController,
            curve: Interval(
              stagger,
              (stagger + 0.45).clamp(0.0, 1.0),
              curve: AppMotion.emphasized,
            ),
          ),
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: FadeTransition(
        opacity: fade,
        child: SlideTransition(
          position: slide,
          child: NotificationSwipeCard(
            key: ValueKey<String>('notification-${item.id}'),
            item: item,
            onTap: () => _openNotification(item),
            groupCount: groupCount,
            markReadIcon: item.isRead
                ? Icons.mark_email_unread_rounded
                : Icons.mark_email_read_rounded,
            markReadSemanticLabel: item.isRead
                ? context.l10n.notificationsSwipeMarkUnread
                : context.l10n.notificationsSwipeMarkRead,
            archiveIcon: Icons.archive_outlined,
            archiveSemanticLabel: context.l10n.notificationsSwipeArchive,
            markReadColor: AppColors.primaryDark,
            archiveColor: AppColors.textMuted,
            onSwipeMarkRead: () => _toggleReadFromSwipe(item),
            onSwipeArchive: () => _archiveNotification(item),
          ),
        ),
      ),
    );
  }

  List<Widget> _notificationsScrollSlivers(BuildContext context) {
    final List<Widget> slivers = <Widget>[
      SliverToBoxAdapter(child: _buildHeader(context)),
      SliverToBoxAdapter(child: _buildFilters(context)),
      if (_unreadCount > 0)
        SliverToBoxAdapter(child: _buildUnreadSummary(context)),
      SliverToBoxAdapter(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _buildInteractionHint(context),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    ];

    if (_isLoading) {
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) =>
                  const _NotificationShimmerTile(),
              childCount: 6,
            ),
          ),
        ),
      );
      return slivers;
    }

    if (_loadErrorMessage != null && _items.isEmpty) {
      slivers.add(
        SliverFillRemaining(
          hasScrollBody: false,
          child: _buildErrorState(context),
        ),
      );
      return slivers;
    }

    if (_visibleItems.isEmpty) {
      slivers.add(
        SliverFillRemaining(
          hasScrollBody: false,
          child: _buildEmptyState(context),
        ),
      );
      return slivers;
    }

    _appendInboxContentSlivers(slivers, animationIndexStart: 0);
    if (_loadMoreFailed) {
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xl,
          ),
          sliver: SliverToBoxAdapter(
            child: OutlinedButton.icon(
              onPressed: () {
                _pagination.loadMoreFailed = false;
                _pagination.requestLoadMore();
                _loadNotifications(reset: false, onlyUnread: _inboxUnreadOnly);
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(context.l10n.notificationsRetryLoadingMore),
            ),
          ),
        ),
      );
    } else {
      slivers.add(
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
      );
    }

    if (_isLoadingMore) {
      slivers.add(
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: AppLoadingIndicator(size: AppLoadingIndicatorSize.sm),
              ),
            ),
          ),
        ),
      );
    }

    return slivers;
  }
}
