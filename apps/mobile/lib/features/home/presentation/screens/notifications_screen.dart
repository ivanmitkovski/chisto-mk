import 'dart:async';

import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/home/domain/models/feed_notification.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/presentation/screens/pollution_site_detail_screen.dart';
import 'package:chisto_mobile/features/notifications/data/notification_open_diagnostics.dart';
import 'package:chisto_mobile/features/notifications/domain/notifications_grouping.dart';
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
  bool _loadMoreFailed = false;
  String? _loadErrorMessage;
  int _page = 1;
  bool _showUnreadOnly = false;
  bool _queryOnlyUnread = false;
  final Set<String> _archivedNotificationIds = <String>{};
  List<NotificationPreference> _preferences = const <NotificationPreference>[];
  bool _isPreferencesLoading = false;
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
    _loadNotifications(reset: true, onlyUnread: false);
    unawaited(_loadPreferences());
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications({bool reset = true, bool? onlyUnread}) async {
    final bool targetOnlyUnread = onlyUnread ?? _queryOnlyUnread;
    if (reset) {
      setState(() {
        _isLoading = true;
        _loadErrorMessage = null;
        _loadMoreFailed = false;
        _queryOnlyUnread = targetOnlyUnread;
      });
    }
    try {
      final int targetPage = reset ? 1 : _page + 1;
      final result = await ServiceLocator.instance.notificationsRepository
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
    _loadNotifications(reset: false, onlyUnread: _queryOnlyUnread);
  }

  List<UserNotification> get _visibleItems {
    final List<UserNotification> base = _items
        .where((UserNotification n) => !_archivedNotificationIds.contains(n.id))
        .toList();
    if (!_showUnreadOnly) return base;
    return base.where((UserNotification n) => !n.isRead).toList();
  }

  List<NotificationSectionGroup> get _sections =>
      groupNotificationsByDay(_visibleItems);

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
      await ServiceLocator.instance.notificationsRepository.markAllAsRead();
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

  PollutionSite? _findSiteById(String id) {
    for (final PollutionSite site in widget.availableSites) {
      if (site.id == id) return site;
    }
    return null;
  }

  Future<void> _openNotification(UserNotification item) async {
    AppHaptics.tap();
    NotificationOpenDiagnostics.recordOpenAttempt('list_tap');
    if (!item.isRead) {
      _setReadState(item, true);
      try {
        await ServiceLocator.instance.notificationsRepository.markAsRead(
          item.id,
        );
        unawaited(_refreshUnreadCountFromServer());
      } catch (_) {
        if (!mounted) return;
        _setReadState(item, false);
      }
    }
    final String? siteId = item.targetSiteId;
    if (siteId == null) return;
    PollutionSite? site = _findSiteById(siteId);
    if (site == null) {
      try {
        site = await ServiceLocator.instance.sitesRepository.getSiteById(
          siteId,
        );
      } catch (_) {}
    }
    if (site == null) {
      NotificationOpenDiagnostics.recordOpenFailure('site_missing');
      if (mounted) {
        AppSnack.show(
          context,
          message: context.l10n.notificationsSiteUnavailable,
          type: AppSnackType.warning,
        );
      }
      return;
    }

    AppHaptics.softTransition();
    if (!mounted) return;
    NotificationOpenDiagnostics.recordOpenSuccess('list_tap');
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PollutionSiteDetailScreen(
          site: site!,
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

  Future<void> _toggleReadFromSwipe(UserNotification item) async {
    final bool nextRead = !item.isRead;
    _setReadState(item, nextRead);
    if (nextRead) {
      try {
        await ServiceLocator.instance.notificationsRepository.markAsRead(
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
    AppSnack.show(
      context,
      message: context.l10n.notificationsMarkedUnreadLocal,
      type: AppSnackType.info,
    );
  }

  void _archiveNotification(UserNotification item) {
    AppHaptics.light();
    setState(() {
      _archivedNotificationIds.add(item.id);
      _unreadCount = _items
          .where(
            (UserNotification n) =>
                !_archivedNotificationIds.contains(n.id) && !n.isRead,
          )
          .length;
    });
    AppSnack.show(
      context,
      message: context.l10n.notificationsArchivedFromView,
      type: AppSnackType.info,
    );
  }

  Future<void> _handleRefresh() async {
    AppHaptics.medium();
    await _loadNotifications(reset: true, onlyUnread: _showUnreadOnly);
  }

  Future<void> _refreshUnreadCountFromServer() async {
    try {
      final int latest = await ServiceLocator.instance.notificationsRepository
          .getUnreadCount();
      if (!mounted) return;
      setState(() => _unreadCount = latest);
    } catch (_) {}
  }

  Future<void> _loadPreferences() async {
    setState(() => _isPreferencesLoading = true);
    try {
      final prefs = await ServiceLocator.instance.notificationsRepository
          .getPreferences();
      if (!mounted) return;
      setState(() {
        _preferences = prefs;
      });
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
      }
    }
  }

  Future<void> _togglePreference(UserNotificationType type, bool muted) async {
    final int index = _preferences.indexWhere((p) => p.type == type);
    if (index < 0) return;
    final NotificationPreference previous = _preferences[index];
    setState(() {
      _preferences = _preferences
          .map((p) => p.type == type ? p.copyWith(muted: muted) : p)
          .toList();
    });
    try {
      final updated = await ServiceLocator.instance.notificationsRepository
          .setPreference(type: type, muted: muted);
      if (!mounted) return;
      setState(() {
        _preferences = _preferences
            .map((p) => p.type == type ? updated : p)
            .toList();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _preferences = _preferences
            .map((p) => p.type == type ? previous : p)
            .toList();
      });
      AppSnack.show(
        context,
        message: context.l10n.notificationsPreferenceUpdateFailed,
        type: AppSnackType.warning,
      );
    }
  }

  void _openPreferencesSheet() {
    AppHaptics.tap();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.panelBackground,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusSheet),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: AppSpacing.sheetHandle,
                      height: AppSpacing.sheetHandleHeight,
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusXs,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    context.l10n.notificationsPrefsSheetTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    context.l10n.notificationsPrefsSheetSubtitle,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (_isPreferencesLoading)
                    const Center(child: CircularProgressIndicator())
                  else
                    ..._preferences.map(
                      (pref) => SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: Text(_notificationTypeLabel(context.l10n, pref.type)),
                        subtitle: Text(
                          pref.muted
                              ? context.l10n.notificationsPrefMuted
                              : context.l10n.notificationsPrefEnabled,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textMuted),
                        ),
                        value: pref.muted,
                        onChanged: (value) =>
                            _togglePreference(pref.type, value),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _notificationTypeLabel(AppLocalizations l10n, UserNotificationType type) {
    switch (type) {
      case UserNotificationType.siteUpdate:
        return l10n.notificationsTypeSiteUpdates;
      case UserNotificationType.reportStatus:
        return l10n.notificationsTypeReportStatus;
      case UserNotificationType.upvote:
        return l10n.notificationsTypeUpvotes;
      case UserNotificationType.comment:
        return l10n.notificationsTypeComments;
      case UserNotificationType.nearbyReport:
        return l10n.notificationsTypeNearbyReports;
      case UserNotificationType.cleanupEvent:
        return l10n.notificationsTypeCleanupEvents;
      case UserNotificationType.system:
        return l10n.notificationsTypeSystem;
    }
  }

  List<Widget> _buildSectionedChildren(BuildContext context) {
    final List<Widget> children = <Widget>[];
    int animationIndex = 0;
    for (final NotificationSectionGroup section in _sections) {
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
              await _toggleReadFromSwipe(item);
              AppHaptics.tap();
              return false;
            }
            _archiveNotification(item);
            return false;
          },
          background: SwipeActionBackground(
            icon: item.isRead
                ? Icons.mark_email_unread_rounded
                : Icons.mark_email_read_rounded,
            label: item.isRead
                ? context.l10n.notificationsSwipeMarkUnread
                : context.l10n.notificationsSwipeMarkRead,
            alignment: Alignment.centerLeft,
            color: AppColors.primaryDark,
          ),
          secondaryBackground: SwipeActionBackground(
            icon: Icons.archive_outlined,
            label: context.l10n.notificationsSwipeArchive,
            alignment: Alignment.centerRight,
            color: AppColors.textMuted,
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
    final double topHotZoneHeight =
        MediaQuery.of(context).padding.top + AppSpacing.xs;
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
                      ? _buildLoadingSkeleton()
                      : _loadErrorMessage != null && _items.isEmpty
                      ? _buildErrorState(context)
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
                                    children: <Widget>[
                                      ..._buildSectionedChildren(context),
                                      if (_loadMoreFailed)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: AppSpacing.sm,
                                          ),
                                          child: OutlinedButton.icon(
                                            onPressed: () {
                                              setState(() {
                                                _loadMoreFailed = false;
                                                _isLoadingMore = true;
                                              });
                                              _loadNotifications(
                                                reset: false,
                                                onlyUnread: _queryOnlyUnread,
                                              );
                                            },
                                            icon: const Icon(
                                              Icons.refresh_rounded,
                                              size: 18,
                                            ),
                                            label: Text(
                                              context.l10n
                                                  .notificationsRetryLoadingMore,
                                            ),
                                          ),
                                        ),
                                    ],
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
              label: context.l10n.notificationsScrollToTopSemantic,
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
              label: context.l10n.notificationsScrollToTopSemantic,
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
                    GestureDetector(
                      onLongPress: () {
                        // Dev-safe preview so notification UX can be validated before
                        // APNs/Firebase production credentials are available.
                        ServiceLocator.instance.pushNotificationService
                            .showDebugLocalNotification();
                        AppSnack.show(
                          context,
                          message: context.l10n.notificationsDebugPreviewTriggered,
                          type: AppSnackType.info,
                        );
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Text(
                        _unreadCount == 0
                            ? context.l10n.notificationsAllCaughtUp
                            : context.l10n.notificationsUnreadUpdatesCount(_unreadCount),
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
            label: context.l10n.notificationsFilterAll,
            selected: !_showUnreadOnly,
            onTap: () {
              if (!_showUnreadOnly) return;
              AppHaptics.tap();
              setState(() => _showUnreadOnly = false);
              _loadNotifications(reset: true, onlyUnread: false);
            },
          ),
          const SizedBox(width: AppSpacing.sm),
          NotificationFilterPill(
            label: context.l10n.notificationsFilterUnread,
            selected: _showUnreadOnly,
            onTap: () {
              if (_showUnreadOnly) return;
              AppHaptics.tap();
              setState(() => _showUnreadOnly = true);
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
    final String title = _showUnreadOnly
        ? context.l10n.notificationsEmptyUnreadTitle
        : context.l10n.notificationsEmptyAllTitle;
    final String message = _showUnreadOnly
        ? context.l10n.notificationsEmptyUnreadBody
        : context.l10n.notificationsEmptyAllBody;
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
            if (_showUnreadOnly) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                onPressed: () {
                  AppHaptics.tap();
                  setState(() => _showUnreadOnly = false);
                  _loadNotifications(reset: true, onlyUnread: false);
                },
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.divider),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                ),
                child: Text(context.l10n.notificationsShowAll),
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
                  _loadNotifications(reset: true, onlyUnread: _showUnreadOnly),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.l10n.commonRetry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      itemCount: 6,
      itemBuilder: (BuildContext context, int index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Container(
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(AppSpacing.radius18),
            ),
          ),
        );
      },
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
