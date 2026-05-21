part of 'package:chisto_mobile/features/home/presentation/notifications_inbox/notifications_inbox_screen.dart';

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  List<UserNotification> _items = <UserNotification>[];
  int _unreadCount = 0;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _loadMoreFailed = false;
  String? _loadErrorMessage;
  int _page = 1;
  bool _inboxUnreadOnly = false;
  Map<UserNotificationType, NotificationPreference> _preferenceByType =
      <UserNotificationType, NotificationPreference>{};
  bool _isPreferencesLoading = false;
  VoidCallback? _notificationPrefsSheetInvalidate;
  late final AnimationController _entranceController;
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<UserNotification>? _prependSub;
  StreamSubscription<UserNotification>? _updatedSub;
  final Map<String, bool> _expandedGroups = <String, bool>{};
  int? _lastRefreshTick;
  late final NotificationsInboxCoordinator _inboxCoordinator;

  @override
  void initState() {
    super.initState();
    _inboxCoordinator = ref.read(notificationsInboxCoordinatorProvider);
    _inboxCoordinator.onInboxOpened();
    _entranceController = AnimationController(
      vsync: this,
      duration: AppMotion.slow,
    );
    _scrollController.addListener(_onScroll);
    _loadNotifications(reset: true, onlyUnread: false);
    unawaited(_loadPreferences());
    final NotificationsRealtimeService realtime =
        AppBootstrap.instance.notificationsRealtimeService;
    _prependSub = realtime.prependItems.listen(_onRealtimePrepend);
    _updatedSub = realtime.updatedItems.listen(_onRealtimeUpdated);
  }

  void _onRealtimePrepend(UserNotification item) {
    if (!mounted) return;
    final int existing = _items.indexWhere((UserNotification n) => n.id == item.id);
    if (existing != -1) {
      return;
    }
    if (item.type == UserNotificationType.eventChat) {
      final int groupIdx = _indexOfEventChatGroup(item);
      if (groupIdx != -1) {
        setState(() {
          final List<UserNotification> next = <UserNotification>[
            item,
            ..._items.where(
              (UserNotification n) =>
                  n.id != _items[groupIdx].id && !_matchesEventChatGroup(n, item),
            ),
          ];
          _items = next;
        });
        return;
      }
    }
    setState(() {
      _items = <UserNotification>[item, ..._items];
    });
  }

  int _indexOfEventChatGroup(UserNotification item) {
    for (int i = 0; i < _items.length; i++) {
      if (_matchesEventChatGroup(_items[i], item)) {
        return i;
      }
    }
    return -1;
  }

  bool _matchesEventChatGroup(UserNotification row, UserNotification incoming) {
    if (row.type != UserNotificationType.eventChat ||
        incoming.type != UserNotificationType.eventChat) {
      return false;
    }
    final String? groupKey = incoming.groupKey?.trim();
    if (groupKey != null && groupKey.isNotEmpty) {
      return row.groupKey == groupKey;
    }
    final String? eventId = incoming.targetEventId?.trim();
    if (eventId != null && eventId.isNotEmpty) {
      return row.targetEventId == eventId;
    }
    return false;
  }

  void _onRealtimeUpdated(UserNotification item) {
    if (!mounted) return;
    final int idx = _items.indexWhere((UserNotification n) => n.id == item.id);
    if (idx == -1) {
      _onRealtimePrepend(item);
      return;
    }
    setState(() {
      final List<UserNotification> next = List<UserNotification>.from(_items)
        ..removeAt(idx);
      next.insert(0, item);
      _items = next;
    });
  }

  @override
  void dispose() {
    _inboxCoordinator.onInboxClosed();
    _prependSub?.cancel();
    _updatedSub?.cancel();
    _entranceController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications({bool reset = true, bool? onlyUnread}) async {
    final bool targetOnlyUnread = onlyUnread ?? _inboxUnreadOnly;
    if (reset) {
      setState(() {
        _isLoading = true;
        _loadErrorMessage = null;
        _loadMoreFailed = false;
        _inboxUnreadOnly = targetOnlyUnread;
      });
    }
    try {
      final int targetPage = reset ? 1 : _page + 1;
      final result = await AppBootstrap.instance.notificationsRepository
          .getNotifications(
            page: targetPage,
            limit: 30,
            onlyUnread: targetOnlyUnread,
          );
      if (!mounted) return;
      final List<UserNotification> merged = reset
          ? result.notifications
          : <UserNotification>[..._items, ...result.notifications];
      setState(() {
        _items = merged;
        _unreadCount = result.unreadCount;
        _isLoading = false;
        _isLoadingMore = false;
        _page = targetPage;
        _hasMore = merged.length < result.total;
        _loadMoreFailed = false;
        _loadErrorMessage = null;
      });
      if (reset) _entranceController.forward(from: 0);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        if (reset) {
          _loadErrorMessage = _friendlyErrorMessage(context.l10n, error);
        } else {
          _loadMoreFailed = true;
        }
      });
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients ||
        _isLoadingMore ||
        !_hasMore ||
        _isLoading) {
      return;
    }
    final position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - 260) return;
    setState(() => _isLoadingMore = true);
    _loadNotifications(reset: false, onlyUnread: _inboxUnreadOnly);
  }

  List<UserNotification> get _visibleItems => _items;

  List<InboxDaySection> get _daySections => groupInboxNotifications(
        _visibleItems,
        dayTitleFor: (DateTime d) => notificationDayTitle(context.l10n, d),
      );

  String _expandedKey(InboxNotificationGroup group) =>
      '${group.key}@${group.representative.createdAt.toIso8601String().substring(0, 10)}';

  bool _isGroupExpanded(InboxNotificationGroup group) =>
      _expandedGroups[_expandedKey(group)] ?? false;

  void _toggleGroupExpanded(InboxNotificationGroup group) {
    final String key = _expandedKey(group);
    final bool next = !(_expandedGroups[key] ?? false);
    setState(() => _expandedGroups[key] = next);
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
    final List<UserNotification> unread =
        group.items.where((UserNotification n) => !n.isRead).toList();
    if (unread.isEmpty) return;
    final List<UserNotification> previous = _items;
    final int previousUnread = _unreadCount;
    setState(() {
      final Set<String> ids = unread.map((UserNotification n) => n.id).toSet();
      _items = _items
          .map(
            (UserNotification n) =>
                ids.contains(n.id) ? n.copyWith(isRead: true) : n,
          )
          .toList();
      _unreadCount = _items.where((UserNotification n) => !n.isRead).length;
    });
    try {
      await Future.wait(
        unread.map(
          (UserNotification n) => AppBootstrap.instance.notificationsRepository
              .markAsRead(n.id),
        ),
      );
      unawaited(_refreshUnreadCountFromServer());
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items = previous;
        _unreadCount = previousUnread;
      });
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
    setState(() {
      _items = _items
          .map((UserNotification n) => n.isRead ? n : n.copyWith(isRead: true))
          .toList();
      _unreadCount = 0;
    });
    try {
      await AppBootstrap.instance.notificationsRepository.markAllAsRead();
      unawaited(_refreshUnreadCountFromServer());
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items = previousItems;
        _unreadCount = previousUnread;
      });
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
        await AppBootstrap.instance.notificationsRepository.markAsRead(
          item.id,
        );
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
    setState(() {
      _items = _items.map((UserNotification n) {
        if (n.id != item.id) return n;
        return n.copyWith(isRead: isRead);
      }).toList();
      _unreadCount = _items.where((UserNotification n) => !n.isRead).length;
    });
  }

  Future<void> _toggleReadFromSwipe(UserNotification item) async {
    final bool nextRead = !item.isRead;
    _setReadState(item, nextRead);
    if (nextRead) {
      try {
        await AppBootstrap.instance.notificationsRepository.markAsRead(
          item.id,
        );
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
      await AppBootstrap.instance.notificationsRepository.markAsUnread(
        item.id,
      );
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
    setState(() {
      _items = _items.where((UserNotification n) => n.id != item.id).toList();
      _unreadCount = _items.where((UserNotification n) => !n.isRead).length;
    });
    try {
      await AppBootstrap.instance.notificationsRepository
          .archiveNotification(item.id);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items = previousItems;
        _unreadCount = previousUnread;
      });
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
    try {
      final int latest = await AppBootstrap.instance.notificationsRepository
          .getUnreadCount();
      if (!mounted) return;
      setState(() => _unreadCount = latest);
    } catch (_) {}
  }

  Future<void> _loadPreferences() async {
    setState(() => _isPreferencesLoading = true);
    try {
      final prefs = await AppBootstrap.instance.notificationsRepository
          .getPreferences();
      if (!mounted) return;
      setState(() {
        _preferenceByType = preferenceMapFromList(prefs);
      });
      _notificationPrefsSheetInvalidate?.call();
    } catch (_) {
      if (!mounted) return;
      AppSnack.show(
        context,
        message: context.l10n.notificationsPrefsLoadFailed,
        type: AppSnackType.warning,
      );
    } finally {
      if (mounted) {
        setState(() => _isPreferencesLoading = false);
        _notificationPrefsSheetInvalidate?.call();
      }
    }
  }

  void _showSnoozePicker(NotificationPreferenceGroup group) {
    final List<_SnoozeDuration> options = <_SnoozeDuration>[
      _SnoozeDuration(context.l10n.notificationsSnooze1h, const Duration(hours: 1)),
      _SnoozeDuration(context.l10n.notificationsSnooze4h, const Duration(hours: 4)),
      _SnoozeDuration(context.l10n.notificationsSnooze8h, const Duration(hours: 8)),
      _SnoozeDuration(context.l10n.notificationsSnooze24h, const Duration(hours: 24)),
      _SnoozeDuration(context.l10n.notificationsSnooze1w, const Duration(days: 7)),
      _SnoozeDuration(context.l10n.notificationsSnoozePermanent, null),
    ];
    showModalBottomSheet<_SnoozeDuration>(
      context: context,
      backgroundColor: AppColors.panelBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radius18)),
      ),
      builder: (BuildContext ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
                child: Text(
                  context.l10n.notificationsSnoozeTitle,
                  style: Theme.of(ctx).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              for (final _SnoozeDuration opt in options)
                ListTile(
                  title: Text(opt.label),
                  onTap: () => Navigator.of(ctx).pop(opt),
                ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ),
        );
      },
    ).then((_SnoozeDuration? choice) {
      if (choice == null) return;
      final DateTime? mutedUntil = choice.duration != null
          ? DateTime.now().add(choice.duration!)
          : null;
      _snoozeGroupPreference(group, mutedUntil);
    });
  }

  Future<void> _snoozeGroupPreference(
    NotificationPreferenceGroup group,
    DateTime? mutedUntil,
  ) async {
    final Map<UserNotificationType, NotificationPreference> previous =
        Map<UserNotificationType, NotificationPreference>.from(_preferenceByType);
    setState(() {
      _preferenceByType = applyGroupMuteToMap(
        _preferenceByType,
        group,
        muted: true,
        mutedUntil: mutedUntil,
      );
    });
    _notificationPrefsSheetInvalidate?.call();
    try {
      final List<NotificationPreference> updated =
          await Future.wait<NotificationPreference>(
        group.types.map(
          (UserNotificationType type) =>
              AppBootstrap.instance.notificationsRepository.setPreference(
            type: type,
            muted: true,
            mutedUntil: mutedUntil,
          ),
        ),
      );
      if (!mounted) return;
      setState(() {
        for (final NotificationPreference pref in updated) {
          _preferenceByType[pref.type] = pref;
        }
      });
      _notificationPrefsSheetInvalidate?.call();
    } catch (_) {
      if (!mounted) return;
      setState(() => _preferenceByType = previous);
      _notificationPrefsSheetInvalidate?.call();
      AppSnack.show(
        context,
        message: context.l10n.notificationsPreferenceUpdateFailed,
        type: AppSnackType.warning,
      );
    }
  }

  Future<void> _toggleGroupPreference(
    NotificationPreferenceGroup group,
    bool enabled,
  ) async {
    final bool muted = !enabled;
    final Map<UserNotificationType, NotificationPreference> previous =
        Map<UserNotificationType, NotificationPreference>.from(_preferenceByType);
    setState(() {
      _preferenceByType = applyGroupMuteToMap(
        _preferenceByType,
        group,
        muted: muted,
        mutedUntil: null,
      );
    });
    _notificationPrefsSheetInvalidate?.call();
    try {
      final List<NotificationPreference> updated =
          await Future.wait<NotificationPreference>(
        group.types.map(
          (UserNotificationType type) =>
              AppBootstrap.instance.notificationsRepository.setPreference(
            type: type,
            muted: muted,
          ),
        ),
      );
      if (!mounted) return;
      setState(() {
        for (final NotificationPreference pref in updated) {
          _preferenceByType[pref.type] = pref;
        }
      });
      _notificationPrefsSheetInvalidate?.call();
    } catch (_) {
      if (!mounted) return;
      setState(() => _preferenceByType = previous);
      _notificationPrefsSheetInvalidate?.call();
      AppSnack.show(
        context,
        message: context.l10n.notificationsPreferenceUpdateFailed,
        type: AppSnackType.warning,
      );
    }
  }

  void _openPreferencesSheet() {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        useRootNavigator: true,
        isScrollControlled: true,
        useSafeArea: false,
        backgroundColor: AppColors.transparent,
        builder: (sheetContext) {
        return StatefulBuilder(
          builder:
              (BuildContext context, void Function(void Function()) setModalState) {
            _notificationPrefsSheetInvalidate = () => setModalState(() {});
            return ReportSheetScaffold(
              fitToContent: true,
              addBottomInset: true,
              title: context.l10n.notificationsPrefsSheetTitle,
              subtitle: context.l10n.notificationsPrefsSheetSubtitle,
              trailing: ReportCircleIconButton(
                icon: Icons.close_rounded,
                semanticLabel: context.l10n.semanticClose,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                },
              ),
              child: _isPreferencesLoading
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                      child: Center(child: AppLoadingIndicator()),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        for (final NotificationPreferenceGroup group
                            in kNotificationPreferenceGroups)
                          GestureDetector(
                            onLongPress: () {
                              _showSnoozePicker(group);
                            },
                            child: SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                notificationPreferenceGroupTitle(
                                  context.l10n,
                                  group.id,
                                ),
                              ),
                              subtitle: Text(
                                notificationPreferenceGroupSubtitle(
                                  context.l10n,
                                  group,
                                  _preferenceByType,
                                ),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.textMuted),
                              ),
                              value: isNotificationPreferenceGroupEnabled(
                                group,
                                _preferenceByType,
                              ),
                              onChanged: (bool enabled) =>
                                  _toggleGroupPreference(group, enabled),
                            ),
                          ),
                      ],
                    ),
            );
          },
        );
      },
      ).whenComplete(() {
        _notificationPrefsSheetInvalidate = null;
      }),
    );
  }

  void _appendInboxContentSlivers(
    List<Widget> slivers, {
    required int animationIndexStart,
  }) {
    int animationIndex = animationIndexStart;
    for (final InboxDaySection day in _daySections) {
      slivers.add(
        SliverPersistentHeader(
          pinned: true,
          delegate: NotificationDayHeaderDelegate(title: day.title),
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
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                final InboxNotificationGroup group = day.groups[index];
                if (group.isGrouped) {
                  return _buildAnimatedGroupRow(group, animationIndex + index);
                }
                return _buildAnimatedNotificationRow(
                  group.representative,
                  animationIndex + index,
                );
              },
              childCount: day.groups.length,
            ),
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
              key: ValueKey<String>('notification-group-${_expandedKey(group)}'),
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

  Widget _buildAnimatedNotificationRow(UserNotification item, int index, {int groupCount = 1}) {
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
                setState(() {
                  _loadMoreFailed = false;
                  _isLoadingMore = true;
                });
                _loadNotifications(
                  reset: false,
                  onlyUnread: _inboxUnreadOnly,
                );
              },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(context.l10n.notificationsRetryLoadingMore),
            ),
          ),
        ),
      );
    } else {
      slivers.add(const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)));
    }

    if (_isLoadingMore) {
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
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

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(notificationsInboxRefreshTickProvider, (
      int? previous,
      int next,
    ) {
      if (previous == null || next == _lastRefreshTick) return;
      _lastRefreshTick = next;
      if (!_isLoading) {
        unawaited(_loadNotifications(reset: true, onlyUnread: _inboxUnreadOnly));
      }
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
                onTap: () {
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
              label: context.l10n.notificationsScrollToTopSemantic,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
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
                  textStyle: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
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
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _unreadCount == 0
                          ? context.l10n.notificationsAllCaughtUp
                          : context.l10n.notificationsUnreadUpdatesCount(_unreadCount),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
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
            label: context.l10n.notificationsFilterAll,
            selected: !_inboxUnreadOnly,
            onTap: () {
              if (!_inboxUnreadOnly) return;
              setState(() => _inboxUnreadOnly = false);
              _loadNotifications(reset: true, onlyUnread: false);
            },
          ),
          const SizedBox(width: AppSpacing.sm),
          NotificationFilterPill(
            label: context.l10n.notificationsFilterUnread,
            selected: _inboxUnreadOnly,
            onTap: () {
              if (_inboxUnreadOnly) return;
              setState(() => _inboxUnreadOnly = true);
              _loadNotifications(reset: true, onlyUnread: true);
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
          context.l10n.notificationsSwipeHint,
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
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
            ),
            if (_inboxUnreadOnly) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              AppButton.outlined(
                label: context.l10n.notificationsShowAll,
                onPressed: () {
                  setState(() => _inboxUnreadOnly = false);
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
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _loadErrorMessage ?? context.l10n.notificationsErrorLoadFallback,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
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

  String _friendlyErrorMessage(AppLocalizations l10n, Object error) {
    if (error is AppError) {
      if (error.code == 'NETWORK_ERROR' || error.code == 'TIMEOUT') {
        return l10n.notificationsErrorNetwork;
      }
      return error.message;
    }
    return l10n.notificationsErrorGeneric;
  }
}
