import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/home/domain/models/feed_notification.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/presentation/screens/pollution_site_detail_screen.dart';
import 'package:chisto_mobile/features/notifications/domain/models/user_notification.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/notifications/notification_widgets.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:chisto_mobile/shared/widgets/app_back_button.dart';
import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    this.availableSites = const <PollutionSite>[],
  });

  final List<PollutionSite> availableSites;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  List<UserNotification> _items = <UserNotification>[];
  int _unreadCount = 0;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 1;
  bool _showUnreadOnly = false;
  late final AnimationController _entranceController;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: AppMotion.slow,
    );
    _scrollController.addListener(_onScroll);
    _loadNotifications();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications({bool reset = true}) async {
    try {
      final int targetPage = reset ? 1 : _page + 1;
      final result = await ServiceLocator.instance.notificationsRepository
          .getNotifications(
        page: targetPage,
        limit: 30,
        onlyUnread: false,
      );
      if (!mounted) return;
      setState(() {
        _items = reset
            ? result.notifications
            : <UserNotification>[..._items, ...result.notifications];
        _unreadCount = result.unreadCount;
        _isLoading = false;
        _isLoadingMore = false;
        _page = targetPage;
        _hasMore = result.notifications.length >= result.limit;
      });
      if (reset) _entranceController.forward(from: 0);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _isLoadingMore || !_hasMore || _isLoading) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - 260) return;
    setState(() => _isLoadingMore = true);
    _loadNotifications(reset: false);
  }

  List<UserNotification> get _visibleItems {
    if (!_showUnreadOnly) return _items;
    return _items.where((UserNotification n) => !n.isRead).toList();
  }

  List<_NotificationSection> get _sections {
    final List<_NotificationSection> sections = <_NotificationSection>[];
    String? currentLabel;
    List<UserNotification> bucket = <UserNotification>[];
    for (final UserNotification item in _visibleItems) {
      final String label = _dayLabel(item.createdAt);
      currentLabel ??= label;
      if (label != currentLabel) {
        sections.add(_NotificationSection(title: currentLabel, items: bucket));
        currentLabel = label;
        bucket = <UserNotification>[];
      }
      bucket.add(item);
    }
    if (currentLabel != null && bucket.isNotEmpty) {
      sections.add(_NotificationSection(title: currentLabel, items: bucket));
    }
    return sections;
  }

  void _close() {
    Navigator.of(context).pop();
  }

  Future<void> _scrollToTop() async {
    if (!_scrollController.hasClients) return;
    await _scrollController.animateTo(
      0,
      duration: AppMotion.standard,
      curve: AppMotion.emphasized,
    );
  }

  Future<void> _markAllRead() async {
    if (_unreadCount == 0) return;
    AppHaptics.medium();
    try {
      await ServiceLocator.instance.notificationsRepository.markAllAsRead();
    } catch (_) {}
    setState(() {
      _items = _items
          .map((UserNotification n) => n.isRead ? n : n.copyWith(isRead: true))
          .toList();
      _unreadCount = 0;
    });
    if (mounted) {
      AppSnack.show(
        context,
        message: 'All notifications marked as read',
        type: AppSnackType.success,
      );
    }
  }

  PollutionSite? _findSiteById(String id) {
    for (final PollutionSite site in widget.availableSites) {
      if (site.id == id) return site;
    }
    return null;
  }

  Future<void> _openNotification(UserNotification item) async {
    AppHaptics.tap();
    if (!item.isRead) {
      _setReadState(item, true);
      try {
        await ServiceLocator.instance.notificationsRepository.markAsRead(item.id);
      } catch (_) {
        if (!mounted) return;
        _setReadState(item, false);
      }
    }
    final String? siteId = item.targetSiteId;
    if (siteId == null) return;
    final PollutionSite? site = _findSiteById(siteId);
    if (site == null) {
      if (mounted) {
        AppSnack.show(
          context,
          message: 'This site is no longer available.',
          type: AppSnackType.warning,
        );
      }
      return;
    }

    AppHaptics.softTransition();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PollutionSiteDetailScreen(
          site: site,
          initialTabIndex: int.tryParse(item.targetTab ?? '') ?? 0,
        ),
      ),
    );
  }

  void _setReadState(UserNotification item, bool isRead) {
    setState(() {
      _items = _items.map((UserNotification n) {
        if (n.id != item.id) return n;
        return n.copyWith(isRead: isRead);
      }).toList();
      _unreadCount = _items.where((UserNotification n) => !n.isRead).length;
    });
  }

  void _deleteNotification(UserNotification item) {
    AppHaptics.light();
    setState(() {
      _items = _items.where((UserNotification n) => n.id != item.id).toList();
      _unreadCount = _items.where((UserNotification n) => !n.isRead).length;
    });
    AppSnack.show(
      context,
      message: 'Notification removed',
      type: AppSnackType.info,
    );
  }

  Future<void> _handleRefresh() async {
    AppHaptics.medium();
    await _loadNotifications(reset: true);
  }

  List<Widget> _buildSectionedChildren(BuildContext context) {
    final List<Widget> children = <Widget>[];
    int animationIndex = 0;
    for (final _NotificationSection section in _sections) {
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xs,
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.xs,
          ),
          child: Text(
            section.title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      );
      for (final UserNotification item in section.items) {
        children.add(_buildAnimatedNotificationRow(item, animationIndex));
        animationIndex += 1;
      }
    }
    return children;
  }

  Widget _buildAnimatedNotificationRow(UserNotification item, int index) {
    final double stagger = (index * 0.06).clamp(0.0, 0.5);
    final Animation<double> fade = CurvedAnimation(
      parent: _entranceController,
      curve: Interval(
        stagger,
        (stagger + 0.45).clamp(0.0, 1.0),
          curve: AppMotion.standardCurve,
      ),
    );
    final Animation<Offset> slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Interval(
        stagger,
        (stagger + 0.45).clamp(0.0, 1.0),
          curve: AppMotion.emphasized,
      ),
    ));

    final _LegacyNotification adapted = _LegacyNotification.fromServer(item);

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide,
        child: Dismissible(
          key: ValueKey<String>('notification-${item.id}'),
          direction: DismissDirection.horizontal,
          confirmDismiss: (DismissDirection direction) async {
            if (direction == DismissDirection.startToEnd) {
              _setReadState(item, !item.isRead);
              AppHaptics.tap();
              return false;
            }
            _deleteNotification(item);
            return true;
          },
          background: SwipeActionBackground(
            icon: item.isRead
                ? Icons.mark_email_unread_rounded
                : Icons.mark_email_read_rounded,
            label: item.isRead ? 'Mark unread' : 'Mark read',
            alignment: Alignment.centerLeft,
            color: AppColors.primaryDark,
          ),
          secondaryBackground: const SwipeActionBackground(
            icon: Icons.delete_outline_rounded,
            label: 'Delete',
            alignment: Alignment.centerRight,
            color: AppColors.accentDanger,
          ),
          child: NotificationTile(
            item: adapted.toFeedNotification(),
            onTap: () => _openNotification(item),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double topHotZoneHeight = MediaQuery.of(context).padding.top + AppSpacing.xs;
    return Scaffold(
      backgroundColor: AppColors.appBackground,
      body: Stack(
        children: <Widget>[
          SafeArea(
            bottom: false,
            child: Column(
              children: <Widget>[
                _buildHeader(context),
                _buildFilters(context),
                if (_unreadCount > 0) _buildUnreadSummary(context),
                _buildInteractionHint(context),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: _handleRefresh,
                          color: AppColors.primaryDark,
                          child: AnimatedSwitcher(
                            duration: AppMotion.medium,
                            switchInCurve: AppMotion.emphasized,
                            switchOutCurve: Curves.easeInCubic,
                            child: _visibleItems.isEmpty
                                ? _buildEmptyState(context)
                                : ListView(
                                    key: ValueKey<bool>(_showUnreadOnly),
                                    controller: _scrollController,
                                    padding: const EdgeInsets.fromLTRB(
                                      AppSpacing.lg,
                                      0,
                                      AppSpacing.lg,
                                      AppSpacing.xl,
                                    ),
                                    physics: const BouncingScrollPhysics(
                                      parent: AlwaysScrollableScrollPhysics(),
                                    ),
                                    children: _buildSectionedChildren(context),
                                  ),
                          ),
                        ),
                ),
                if (_isLoadingMore)
                  const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.md),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
          Positioned(
              top: 0,
              left: 0,
              width: 112,
              height: topHotZoneHeight,
              child: Semantics(
                button: true,
                label: 'Scroll notifications to top',
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    AppHaptics.tap();
                    _scrollToTop();
                  },
                ),
              ),
            ),
          Positioned(
              top: 0,
              right: 0,
              width: 112,
              height: topHotZoneHeight,
              child: Semantics(
                button: true,
                label: 'Scroll notifications to top',
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    AppHaptics.tap();
                    _scrollToTop();
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              AppBackButton(onPressed: _close),
              const Spacer(),
              FilledButton.tonal(
                onPressed: _unreadCount > 0 ? _markAllRead : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.inputFill,
                  foregroundColor: AppColors.textPrimary,
                  textStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 8,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Mark all read'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Notifications',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                    ),
                    const SizedBox(height: 2),
                    GestureDetector(
                      onLongPress: () {
                        // Dev-safe preview so notification UX can be validated before
                        // APNs/Firebase production credentials are available.
                        ServiceLocator.instance.pushNotificationService
                            .showDebugLocalNotification();
                        AppSnack.show(
                          context,
                          message:
                              'Local notification preview triggered',
                          type: AppSnackType.info,
                        );
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Text(
                        _unreadCount == 0
                            ? 'All caught up'
                            : '$_unreadCount unread updates',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          NotificationFilterPill(
            label: 'All',
            selected: !_showUnreadOnly,
            onTap: () {
              AppHaptics.tap();
              setState(() => _showUnreadOnly = false);
            },
          ),
          const SizedBox(width: AppSpacing.sm),
          NotificationFilterPill(
            label: 'Unread',
            selected: _showUnreadOnly,
            onTap: () {
              AppHaptics.tap();
              setState(() => _showUnreadOnly = true);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUnreadSummary(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppSpacing.radius14),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.22),
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_active_outlined,
                size: 16,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                _unreadCount == 1
                    ? '1 unread notification needs your attention'
                    : '$_unreadCount unread notifications need your attention',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractionHint(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          'Swipe right to mark read/unread \u00b7 left to delete',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted.withValues(alpha: 0.85),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final String title = _showUnreadOnly ? 'No unread notifications' : 'No notifications yet';
    final String message = _showUnreadOnly
        ? 'You are all caught up. New updates will appear here.'
        : 'When people react to sites and actions, you will see updates here.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.inputFill,
                borderRadius: BorderRadius.circular(AppSpacing.radius18),
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                color: AppColors.textMuted,
                size: 28,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
            if (_showUnreadOnly) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                onPressed: () {
                  AppHaptics.tap();
                  setState(() => _showUnreadOnly = false);
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.divider),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                ),
                child: const Text('Show all notifications'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _dayLabel(DateTime value) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime input = DateTime(value.year, value.month, value.day);
    final int diff = today.difference(input).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return '${value.day.toString().padLeft(2, '0')}.${value.month.toString().padLeft(2, '0')}.${value.year}';
  }
}

class _NotificationSection {
  const _NotificationSection({required this.title, required this.items});
  final String title;
  final List<UserNotification> items;
}

class _LegacyNotification {
  _LegacyNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.isRead,
    required this.type,
    this.targetSiteId,
    this.targetTabIndex,
  });

  factory _LegacyNotification.fromServer(UserNotification n) {
    return _LegacyNotification(
      id: n.id,
      title: n.title,
      message: n.body,
      createdAt: n.createdAt,
      isRead: n.isRead,
      type: _mapType(n.type),
      targetSiteId: n.targetSiteId,
      targetTabIndex: int.tryParse(n.targetTab ?? ''),
    );
  }

  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final FeedNotificationType type;
  final String? targetSiteId;
  final int? targetTabIndex;

  static FeedNotificationType _mapType(UserNotificationType type) {
    switch (type) {
      case UserNotificationType.upvote:
      case UserNotificationType.comment:
        return FeedNotificationType.action;
      case UserNotificationType.system:
        return FeedNotificationType.system;
      default:
        return FeedNotificationType.update;
    }
  }

  FeedNotification toFeedNotification() {
    return FeedNotification(
      id: id,
      title: title,
      message: message,
      createdAt: createdAt,
      type: type,
      isRead: isRead,
      targetSiteId: targetSiteId,
      targetTabIndex: targetTabIndex,
    );
  }
}
