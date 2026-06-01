part of 'package:feature_notifications/src/presentation/notifications_inbox/notifications_inbox_screen.dart';

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late final NotificationsInboxListController _pagination;
  Map<UserNotificationType, NotificationPreference> _preferenceByType =
      <UserNotificationType, NotificationPreference>{};
  bool _isPreferencesLoading = false;
  VoidCallback? _notificationPrefsSheetInvalidate;
  late final AnimationController _entranceController;
  final ScrollController _scrollController = ScrollController();
  int? _lastRefreshTick;
  bool _pendingInboxRefresh = false;
  bool _initialLoadScheduled = false;
  late final NotificationsInboxCoordinator _inboxCoordinator;

  List<UserNotification> get _items => _pagination.items;
  int get _unreadCount => _pagination.unreadCount;
  bool get _isLoading => _pagination.isLoading;
  bool get _isLoadingMore => _pagination.isLoadingMore;
  bool get _loadMoreFailed => _pagination.loadMoreFailed;
  String? get _loadErrorMessage => _pagination.loadErrorMessage;
  bool get _inboxUnreadOnly => _pagination.inboxUnreadOnly;

  @override
  void initState() {
    super.initState();
    _pagination = NotificationsInboxListController(
      ref: ref,
      onStateChanged: () {
        if (mounted) {
          setState(() {});
        }
      },
    );
    _inboxCoordinator = ref.read(notificationsInboxCoordinatorProvider);
    _inboxCoordinator.onInboxOpened();
    _entranceController = AnimationController(
      vsync: this,
      duration: AppMotion.slow,
    );
    _scrollController.addListener(_onScroll);
    _pagination.attachRealtime();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialLoadScheduled) {
      return;
    }
    _initialLoadScheduled = true;
    // Wait until localizations and inherited widgets are available. Loading in
    // [initState] can throw on [context.l10n] after hot restart and leave the
    // skeleton visible forever.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(_loadNotifications(reset: true, onlyUnread: false));
      unawaited(_loadPreferences());
    });
  }

  @override
  void dispose() {
    _inboxCoordinator.onInboxClosed();
    _pagination.dispose();
    _entranceController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications({bool reset = true, bool? onlyUnread}) async {
    if (!mounted) {
      return;
    }
    final AppLocalizations l10n = context.l10n;
    try {
      await _pagination.loadNotifications(
        reset: reset,
        onlyUnread: onlyUnread,
        l10n: l10n,
      );
    } catch (error, stackTrace) {
      AppLog.warn(
        'notifications_inbox: load failed before repository call',
        error: error,
        stackTrace: stackTrace,
      );
      if (!mounted) {
        return;
      }
      if (reset) {
        _pagination.forceLoadEndedWithError(l10n: context.l10n, error: error);
      }
    }
    if (reset && mounted) {
      unawaited(_entranceController.forward(from: 0));
    }
    _flushPendingInboxRefresh();
  }

  void _onInboxRefreshTick(int next) {
    if (next == _lastRefreshTick) {
      return;
    }
    _lastRefreshTick = next;
    if (_isLoading) {
      _pendingInboxRefresh = true;
      return;
    }
    unawaited(_loadNotifications(reset: true, onlyUnread: _inboxUnreadOnly));
  }

  void _flushPendingInboxRefresh() {
    if (!_pendingInboxRefresh || !mounted || _isLoading) {
      return;
    }
    _pendingInboxRefresh = false;
    unawaited(_loadNotifications(reset: true, onlyUnread: _inboxUnreadOnly));
  }

  void _onScroll() {
    if (!_pagination.shouldLoadMore(scrollController: _scrollController)) {
      return;
    }
    _pagination.requestLoadMore();
    _loadNotifications(reset: false, onlyUnread: _inboxUnreadOnly);
  }

  List<UserNotification> get _visibleItems => _items;

  List<InboxDaySection> get _daySections => groupInboxNotifications(
    _visibleItems,
    dayTitleFor: (DateTime d) => notificationDayTitle(context.l10n, d),
  );

  String _expandedKey(InboxNotificationGroup group) =>
      _pagination.expandedGroupKey(group);

  bool _isGroupExpanded(InboxNotificationGroup group) =>
      _pagination.isGroupExpanded(group);

  void _toggleGroupExpanded(InboxNotificationGroup group) {
    final bool next = !_pagination.isGroupExpanded(group);
    _pagination.toggleGroupExpanded(group);
    if (next) {
      final List<String> names = group.topActors
          .map((a) => a.displayName)
          .where((String n) => n.isNotEmpty)
          .toList();
      final String summary = notificationGroupSummary(
        context.l10n,
        actorNames: names,
        totalCount: group.items.length,
      );
      if (MediaQuery.supportsAnnounceOf(context)) {
        SemanticsService.sendAnnouncement(
          View.of(context),
          context.l10n.notificationsGroupShowingN(group.items.length, summary),
          Directionality.of(context),
        );
      }
    }
  }

  Future<void> _markGroupRead(InboxNotificationGroup group) async {
    final List<UserNotification> unread = group.items
        .where((UserNotification n) => !n.isRead)
        .toList();
    if (unread.isEmpty) return;
    final List<UserNotification> previous = _items;
    final int previousUnread = _unreadCount;
    _pagination.markGroupReadLocally(group);
    try {
      await Future.wait(
        unread.map(
          (UserNotification n) =>
              ref.read(notificationsRepositoryProvider).markAsRead(n.id),
        ),
      );
      unawaited(_refreshUnreadCountFromServer());
    } catch (_) {
      if (!mounted) return;
      _pagination.restoreItems(previous, previousUnread);
      AppSnack.show(
        context,
        message: context.l10n.notificationsReadStateUpdateFailed,
        type: AppSnackType.warning,
      );
    }
  }

  void _close() {
    Navigator.of(context).pop(_unreadCount);
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
    final List<UserNotification> previousItems = _items;
    final int previousUnread = _unreadCount;
    _pagination.markAllReadLocally();
    try {
      await ref.read(notificationsRepositoryProvider).markAllAsRead();
      unawaited(_refreshUnreadCountFromServer());
    } catch (_) {
      if (!mounted) return;
      _pagination.restoreItems(previousItems, previousUnread);
      AppSnack.show(
        context,
        message: context.l10n.notificationsMarkAllReadFailed,
        type: AppSnackType.warning,
      );
      return;
    }
    if (mounted) {
      AppSnack.show(
        context,
        message: context.l10n.notificationsAllMarkedReadSuccess,
        type: AppSnackType.success,
      );
    }
  }

  Future<void> _openNotification(UserNotification item) async {
    NotificationOpenDiagnostics.recordOpenAttempt('list_tap');
    if (!item.isRead) {
      _setReadState(item, true);
      try {
        await ref.read(notificationsRepositoryProvider).markAsRead(item.id);
        unawaited(_refreshUnreadCountFromServer());
      } catch (_) {
        if (!mounted) return;
        _setReadState(item, false);
      }
    }
    if (!mounted) return;
    await NotificationInboxRouter.open(
      context,
      item,
      availableSites: widget.availableSites,
    );
  }

  void _setReadState(UserNotification item, bool isRead) {
    _pagination.setReadState(item, isRead: isRead);
  }

  Future<void> _toggleReadFromSwipe(UserNotification item) async {
    final bool nextRead = !item.isRead;
    _setReadState(item, nextRead);
    if (nextRead) {
      try {
        await ref.read(notificationsRepositoryProvider).markAsRead(item.id);
        unawaited(_refreshUnreadCountFromServer());
      } catch (_) {
        if (!mounted) return;
        _setReadState(item, !nextRead);
        AppSnack.show(
          context,
          message: context.l10n.notificationsReadStateUpdateFailed,
          type: AppSnackType.warning,
        );
      }
      return;
    }
    try {
      await ref.read(notificationsRepositoryProvider).markAsUnread(item.id);
      unawaited(_refreshUnreadCountFromServer());
    } catch (_) {
      if (!mounted) return;
      _setReadState(item, !nextRead);
      AppSnack.show(
        context,
        message: context.l10n.notificationsReadStateUpdateFailed,
        type: AppSnackType.warning,
      );
    }
  }

  Future<void> _archiveNotification(UserNotification item) async {
    final List<UserNotification> previousItems = _items;
    final int previousUnread = _unreadCount;
    _pagination.removeItem(item.id);
    try {
      await ref
          .read(notificationsRepositoryProvider)
          .archiveNotification(item.id);
    } catch (_) {
      if (!mounted) return;
      _pagination.restoreItems(previousItems, previousUnread);
      AppSnack.show(
        context,
        message: context.l10n.notificationsArchiveFailed,
        type: AppSnackType.warning,
      );
      return;
    }
    if (mounted) {
      AppSnack.show(
        context,
        message: context.l10n.notificationsArchivedFromView,
        type: AppSnackType.info,
      );
    }
  }

  Future<void> _handleRefresh() async {
    await _loadNotifications(reset: true, onlyUnread: _inboxUnreadOnly);
  }

  Future<void> _refreshUnreadCountFromServer() async {
    await _pagination.refreshUnreadCountFromServer();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(notificationsInboxRefreshTickProvider, (
      int? previous,
      int next,
    ) {
      if (previous == null) {
        _lastRefreshTick = next;
        return;
      }
      _onInboxRefreshTick(next);
    });

    final double topHotZoneHeight =
        MediaQuery.of(context).padding.top + AppSpacing.xs;
    return Scaffold(
      backgroundColor: AppColors.appBackground,
      body: Stack(
        children: <Widget>[
          SafeArea(
            bottom: false,
            child: AppRefreshIndicator(
              onRefresh: _handleRefresh,
              child: CustomScrollView(
                key: ValueKey<bool>(_inboxUnreadOnly),
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: _notificationsScrollSlivers(context),
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            width: 112,
            height: topHotZoneHeight,
            child: Semantics(
              button: true,
              label: context.l10n.notificationsScrollToTopSemantic,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _scrollToTop,
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
              label: context.l10n.notificationsScrollToTopSemantic,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _scrollToTop,
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
              IconButton(
                onPressed: _openPreferencesSheet,
                icon: const Icon(Icons.tune_rounded),
                tooltip: context.l10n.notificationsPreferencesTooltip,
              ),
              FilledButton.tonal(
                onPressed: _unreadCount > 0 ? _markAllRead : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.inputFill,
                  foregroundColor: AppColors.textPrimary,
                  textStyle: AppTypographySurfaces.notificationsFilterChip(
                    Theme.of(context).textTheme,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 8,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(context.l10n.notificationsMarkAllRead),
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
                      context.l10n.notificationsTitle,
                      style: AppTypographySurfaces.notificationsScreenTitle(
                        Theme.of(context).textTheme,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _unreadCount == 0
                          ? context.l10n.notificationsAllCaughtUp
                          : context.l10n.notificationsUnreadUpdatesCount(
                              _unreadCount,
                            ),
                      style: AppTypographySurfaces.notificationsScreenSubtitle(
                        Theme.of(context).textTheme,
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
    return NotificationsFilterBar(
      active: _inboxUnreadOnly
          ? NotificationInboxFilter.unread
          : NotificationInboxFilter.all,
      onSelected: (NotificationInboxFilter filter) {
        final bool unreadOnly = filter == NotificationInboxFilter.unread;
        if (unreadOnly == _inboxUnreadOnly) {
          return;
        }
        _loadNotifications(reset: true, onlyUnread: unreadOnly);
      },
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
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
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
                    ? context.l10n.notificationsUnreadBannerOne
                    : context.l10n.notificationsUnreadBannerMany(_unreadCount),
                style: AppTypographySurfaces.notificationsUnreadBanner(
                  Theme.of(context).textTheme,
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
          context.l10n.notificationsSwipeHint,
          style: AppTypographySurfaces.notificationsSwipeHint(
            Theme.of(context).textTheme,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final String title = _inboxUnreadOnly
        ? context.l10n.notificationsEmptyUnreadTitle
        : context.l10n.notificationsEmptyAllTitle;
    final String message = _inboxUnreadOnly
        ? context.l10n.notificationsEmptyUnreadBody
        : context.l10n.notificationsEmptyAllBody;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: AppRadii.xl,
              ),
              child: Icon(
                _inboxUnreadOnly
                    ? Icons.mark_email_read_rounded
                    : Icons.notifications_none_rounded,
                color: AppColors.primaryDark,
                size: 32,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypographySurfaces.notificationsEmptyTitle(
                Theme.of(context).textTheme,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypographySurfaces.notificationsScreenSubtitle(
                Theme.of(context).textTheme,
              ),
            ),
            if (_inboxUnreadOnly) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              AppButton.outlined(
                label: context.l10n.notificationsShowAll,
                onPressed: () {
                  _loadNotifications(reset: true, onlyUnread: false);
                },
                expand: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.wifi_off_rounded,
              size: 34,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.l10n.notificationsErrorLoadTitle,
              style: AppTypographySurfaces.notificationsErrorTitle(
                Theme.of(context).textTheme,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _loadErrorMessage ?? context.l10n.notificationsErrorLoadFallback,
              textAlign: TextAlign.center,
              style: AppTypographySurfaces.notificationsScreenSubtitle(
                Theme.of(context).textTheme,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: () =>
                  _loadNotifications(reset: true, onlyUnread: _inboxUnreadOnly),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.l10n.commonRetry),
            ),
          ],
        ),
      ),
    );
  }
}
