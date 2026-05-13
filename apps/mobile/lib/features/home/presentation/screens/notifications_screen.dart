import 'dart:async';

import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/presentation/screens/pollution_site_detail_screen.dart';
import 'package:chisto_mobile/features/notifications/data/notification_open_diagnostics.dart';
import 'package:chisto_mobile/features/notifications/domain/models/user_notification.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/notifications/notification_widgets.dart';
import 'package:chisto_mobile/features/reports/presentation/widgets/report_surface_primitives.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_snack.dart';
import 'package:chisto_mobile/shared/widgets/app_back_button.dart';
import 'package:chisto_mobile/shared/widgets/app_refresh_indicator.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';

List<NotificationPreference> _dedupeNotificationPreferencesByType(
  List<NotificationPreference> prefs,
) {
  final Set<UserNotificationType> seen = <UserNotificationType>{};
  final List<NotificationPreference> out = <NotificationPreference>[];
  for (final NotificationPreference p in prefs) {
    if (seen.add(p.type)) {
      out.add(p);
    }
  }
  return out;
}

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
  List<NotificationPreference> _preferences = const <NotificationPreference>[];
  bool _isPreferencesLoading = false;
  VoidCallback? _notificationPrefsSheetInvalidate;
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
    if (!_showUnreadOnly) return _items;
    return _items.where((UserNotification n) => !n.isRead).toList();
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
    try {
      await ServiceLocator.instance.notificationsRepository.markAsUnread(
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
    AppHaptics.light();
    final List<UserNotification> previousItems = _items;
    final int previousUnread = _unreadCount;
    setState(() {
      _items = _items.where((UserNotification n) => n.id != item.id).toList();
      _unreadCount = _items.where((UserNotification n) => !n.isRead).length;
    });
    try {
      await ServiceLocator.instance.notificationsRepository
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
        _preferences = _dedupeNotificationPreferencesByType(prefs);
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

  void _showSnoozePicker(UserNotificationType type) {
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
      _snoozePreference(type, mutedUntil);
    });
  }

  Future<void> _snoozePreference(UserNotificationType type, DateTime? mutedUntil) async {
    final int index = _preferences.indexWhere((p) => p.type == type);
    if (index < 0) return;
    final NotificationPreference previous = _preferences[index];
    setState(() {
      _preferences = _dedupeNotificationPreferencesByType(
        _preferences
            .map((p) => p.type == type ? p.copyWith(muted: true, mutedUntil: mutedUntil) : p)
            .toList(),
      );
    });
    _notificationPrefsSheetInvalidate?.call();
    try {
      await ServiceLocator.instance.notificationsRepository
          .setPreference(type: type, muted: true, mutedUntil: mutedUntil);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _preferences = _dedupeNotificationPreferencesByType(
          _preferences
              .map((p) => p.type == type ? previous : p)
              .toList(),
        );
      });
      _notificationPrefsSheetInvalidate?.call();
    }
  }

  Future<void> _togglePreference(UserNotificationType type, bool muted) async {
    final int index = _preferences.indexWhere((p) => p.type == type);
    if (index < 0) return;
    final NotificationPreference previous = _preferences[index];
    setState(() {
      _preferences = _dedupeNotificationPreferencesByType(
        _preferences
            .map((p) => p.type == type ? p.copyWith(muted: muted) : p)
            .toList(),
      );
    });
    _notificationPrefsSheetInvalidate?.call();
    try {
      final updated = await ServiceLocator.instance.notificationsRepository
          .setPreference(type: type, muted: muted);
      if (!mounted) return;
      setState(() {
        _preferences = _dedupeNotificationPreferencesByType(
          _preferences
              .map((p) => p.type == type ? updated : p)
              .toList(),
        );
      });
      _notificationPrefsSheetInvalidate?.call();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _preferences = _dedupeNotificationPreferencesByType(
          _preferences
              .map((p) => p.type == type ? previous : p)
              .toList(),
        );
      });
      _notificationPrefsSheetInvalidate?.call();
      AppSnack.show(
        context,
        message: context.l10n.notificationsPreferenceUpdateFailed,
        type: AppSnackType.warning,
      );
    }
  }

  void _openPreferencesSheet() {
    AppHaptics.tap();
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
                  AppHaptics.tap();
                  Navigator.of(sheetContext).pop();
                },
              ),
              child: _isPreferencesLoading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        for (final NotificationPreference pref in _preferences)
                          GestureDetector(
                            onLongPress: () {
                              AppHaptics.medium();
                              _showSnoozePicker(pref.type);
                            },
                            child: SwitchListTile.adaptive(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                _notificationTypeLabel(context.l10n, pref.type),
                              ),
                              subtitle: Text(
                                _preferenceSubtitle(context.l10n, pref),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: AppColors.textMuted),
                              ),
                              value: !pref.muted,
                              onChanged: (bool enabled) =>
                                  _togglePreference(pref.type, !enabled),
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
      case UserNotificationType.eventChat:
        return l10n.notificationsTypeCleanupEvents;
      case UserNotificationType.system:
        return l10n.notificationsTypeSystem;
      case UserNotificationType.achievement:
        return l10n.notificationsTypeSystem;
      case UserNotificationType.welcome:
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
      final List<CollapsedNotification> collapsed =
          collapseByGroupKey(section.items);
      for (final CollapsedNotification entry in collapsed) {
        children.add(_buildAnimatedNotificationRow(
          entry.representative,
          animationIndex,
          groupCount: entry.groupCount,
        ));
        animationIndex += 1;
      }
    }
    return children;
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

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide,
        child: Material(
          type: MaterialType.transparency,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radius18),
          ),
          clipBehavior: Clip.antiAliasWithSaveLayer,
          child: Dismissible(
            key: ValueKey<String>('notification-${item.id}'),
            direction: DismissDirection.horizontal,
            confirmDismiss: (DismissDirection direction) async {
              if (direction == DismissDirection.startToEnd) {
                await _toggleReadFromSwipe(item);
                AppHaptics.tap();
                return false;
              }
              unawaited(_archiveNotification(item));
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radius18),
              clipBehavior: Clip.antiAliasWithSaveLayer,
              child: NotificationTile(
                item: item,
                onTap: () => _openNotification(item),
                groupCount: groupCount,
              ),
            ),
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

    slivers.add(
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        sliver: SliverList(
          delegate: SliverChildListDelegate.fixed(
            <Widget>[
              ..._buildSectionedChildren(context),
              if (_loadMoreFailed)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
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
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(
                      context.l10n.notificationsRetryLoadingMore,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (_isLoadingMore) {
      slivers.add(
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
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
                key: ValueKey<bool>(_showUnreadOnly),
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
                      onLongPress: kDebugMode
                          ? () {
                              ServiceLocator.instance.pushNotificationService
                                  .showDebugLocalNotification();
                              AppSnack.show(
                                context,
                                message: context.l10n.notificationsDebugPreviewTriggered,
                                type: AppSnackType.info,
                              );
                            }
                          : null,
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
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                _showUnreadOnly
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

  String _preferenceSubtitle(AppLocalizations l10n, NotificationPreference pref) {
    if (!pref.muted) return l10n.notificationsPrefEnabled;
    if (pref.mutedUntil != null && pref.mutedUntil!.isAfter(DateTime.now())) {
      final String time =
          '${pref.mutedUntil!.hour.toString().padLeft(2, '0')}:${pref.mutedUntil!.minute.toString().padLeft(2, '0')}';
      return l10n.notificationsPrefSnoozedUntil(time);
    }
    return l10n.notificationsPrefMuted;
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

class _NotificationShimmerTile extends StatelessWidget {
  const _NotificationShimmerTile();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        height: 96,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radius18),
          color: AppColors.inputFill,
        ),
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    width: 56,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 180,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.divider.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SnoozeDuration {
  const _SnoozeDuration(this.label, this.duration);
  final String label;
  final Duration? duration;
}
