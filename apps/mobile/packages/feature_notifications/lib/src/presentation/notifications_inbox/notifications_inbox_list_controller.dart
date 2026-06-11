import 'dart:async';

import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/l10n/app_error_localizations.dart';
import 'package:chisto_infrastructure/core/logging/app_log.dart';
import 'package:chisto_infrastructure/core/providers/notifications_providers.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:feature_notifications/src/application/notifications_providers.dart';
import 'package:feature_notifications/src/data/notifications_realtime_service.dart';
import 'package:feature_notifications/src/domain/inbox_groups.dart';
import 'package:feature_notifications/src/domain/models/user_notification.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pagination and realtime merge logic for the notifications inbox list.
class NotificationsInboxListController {
  NotificationsInboxListController({
    required this.ref,
    required this.onStateChanged,
  });

  final WidgetRef ref;
  final VoidCallback onStateChanged;

  List<UserNotification> items = <UserNotification>[];
  int unreadCount = 0;
  bool isLoading = true;
  bool isLoadingMore = false;
  bool hasMore = true;
  bool loadMoreFailed = false;
  String? loadErrorMessage;
  int page = 1;
  bool inboxUnreadOnly = false;
  int _loadGeneration = 0;

  StreamSubscription<UserNotification>? _prependSub;
  StreamSubscription<UserNotification>? _updatedSub;

  void attachRealtime() {
    final NotificationsRealtimeService realtime = ref.read(
      notificationsRealtimeServiceProvider,
    );
    _prependSub = realtime.prependItems.listen(_onRealtimePrepend);
    _updatedSub = realtime.updatedItems.listen(_onRealtimeUpdated);
  }

  void dispose() {
    _prependSub?.cancel();
    _updatedSub?.cancel();
  }

  void _notify() => onStateChanged();

  void _onRealtimePrepend(UserNotification item) {
    final int existing = items.indexWhere(
      (UserNotification n) => n.id == item.id,
    );
    if (existing != -1) {
      return;
    }
    if (item.type == UserNotificationType.eventChat) {
      final int groupIdx = _indexOfEventChatGroup(item);
      if (groupIdx != -1) {
        items = <UserNotification>[
          item,
          ...items.where(
            (UserNotification n) =>
                n.id != items[groupIdx].id && !_matchesEventChatGroup(n, item),
          ),
        ];
        _notify();
        return;
      }
    }
    items = <UserNotification>[item, ...items];
    _notify();
  }

  int _indexOfEventChatGroup(UserNotification item) {
    for (int i = 0; i < items.length; i++) {
      if (_matchesEventChatGroup(items[i], item)) {
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
    final int idx = items.indexWhere((UserNotification n) => n.id == item.id);
    if (idx == -1) {
      _onRealtimePrepend(item);
      return;
    }
    final List<UserNotification> next = List<UserNotification>.from(items)
      ..removeAt(idx);
    next.insert(0, item);
    items = next;
    _notify();
  }

  Future<void> loadNotifications({
    bool reset = true,
    bool? onlyUnread,
    required AppLocalizations l10n,
  }) async {
    final bool targetOnlyUnread = onlyUnread ?? inboxUnreadOnly;
    final int generation = ++_loadGeneration;
    if (reset) {
      isLoading = true;
      loadErrorMessage = null;
      loadMoreFailed = false;
      inboxUnreadOnly = targetOnlyUnread;
      _notify();
    }
    try {
      final int targetPage = reset ? 1 : page + 1;
      final result = await ref
          .read(notificationsRepositoryProvider)
          .getNotifications(
            page: targetPage,
            limit: 30,
            onlyUnread: targetOnlyUnread,
          );
      if (generation != _loadGeneration) {
        return;
      }
      final List<UserNotification> merged = reset
          ? result.notifications
          : <UserNotification>[...items, ...result.notifications];
      items = merged;
      unreadCount = result.unreadCount;
      isLoading = false;
      isLoadingMore = false;
      page = targetPage;
      hasMore = merged.length < result.total;
      loadMoreFailed = false;
      loadErrorMessage = null;
      _notify();
    } catch (error) {
      if (generation != _loadGeneration) {
        return;
      }
      isLoading = false;
      isLoadingMore = false;
      if (reset) {
        loadErrorMessage = _friendlyErrorMessage(l10n, error);
      } else {
        loadMoreFailed = true;
      }
      _notify();
    }
  }

  void forceLoadEndedWithError({
    required AppLocalizations l10n,
    required Object error,
  }) {
    _loadGeneration++;
    isLoading = false;
    isLoadingMore = false;
    loadErrorMessage = _friendlyErrorMessage(l10n, error);
    _notify();
  }

  Future<void> refreshUnreadCountFromServer() async {
    try {
      unreadCount = await ref
          .read(notificationsRepositoryProvider)
          .getUnreadCount();
      _notify();
    } catch (e, st) {
      AppLog.warn(
        'notifications_inbox: refresh unread count failed',
        error: e,
        stackTrace: st,
      );
    }
  }

  void setReadState(UserNotification item, {required bool isRead}) {
    items = items.map((UserNotification n) {
      if (n.id != item.id) return n;
      return n.copyWith(isRead: isRead);
    }).toList();
    unreadCount = items.where((UserNotification n) => !n.isRead).length;
    _notify();
  }

  void markAllReadLocally() {
    items = items
        .map((UserNotification n) => n.isRead ? n : n.copyWith(isRead: true))
        .toList();
    unreadCount = 0;
    _notify();
  }

  void restoreItems(List<UserNotification> previous, int previousUnread) {
    items = previous;
    unreadCount = previousUnread;
    _notify();
  }

  void removeItem(String id) {
    items = items.where((UserNotification n) => n.id != id).toList();
    unreadCount = items.where((UserNotification n) => !n.isRead).length;
    _notify();
  }

  void markGroupReadLocally(InboxNotificationGroup group) {
    final Set<String> ids = group.items
        .where((UserNotification n) => !n.isRead)
        .map((UserNotification n) => n.id)
        .toSet();
    items = items
        .map(
          (UserNotification n) =>
              ids.contains(n.id) ? n.copyWith(isRead: true) : n,
        )
        .toList();
    unreadCount = items.where((UserNotification n) => !n.isRead).length;
    _notify();
  }

  final Map<String, bool> _expandedGroups = <String, bool>{};

  String expandedGroupKey(InboxNotificationGroup group) =>
      '${group.key}@${group.representative.createdAt.toIso8601String().substring(0, 10)}';

  bool isGroupExpanded(InboxNotificationGroup group) =>
      _expandedGroups[expandedGroupKey(group)] ?? false;

  void toggleGroupExpanded(InboxNotificationGroup group) {
    final String key = expandedGroupKey(group);
    _expandedGroups[key] = !(_expandedGroups[key] ?? false);
    _notify();
  }

  bool shouldLoadMore({required ScrollController scrollController}) {
    if (!scrollController.hasClients ||
        isLoadingMore ||
        !hasMore ||
        isLoading) {
      return false;
    }
    final ScrollPosition position = scrollController.position;
    return position.pixels >= position.maxScrollExtent - 260;
  }

  void requestLoadMore() {
    isLoadingMore = true;
    _notify();
  }

  String _friendlyErrorMessage(AppLocalizations l10n, Object error) {
    if (error is AppError) {
      return localizedAppErrorMessage(l10n, error);
    }
    return l10n.notificationsErrorGeneric;
  }
}
