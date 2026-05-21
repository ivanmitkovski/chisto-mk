import 'dart:async';

import 'package:chisto_mobile/core/auth/auth_state.dart';
import 'package:chisto_mobile/core/config/app_config.dart';
import 'package:chisto_mobile/features/auth/domain/refresh_outcome.dart';
import 'package:chisto_mobile/features/notifications/data/notification_inbox_refresh.dart';
import 'package:chisto_mobile/features/notifications/data/socket_notifications_stream.dart';
import 'package:chisto_mobile/features/notifications/domain/models/user_notification.dart';

/// Connects the notifications WebSocket and updates bell + inbox in real time.
class NotificationsRealtimeService {
  NotificationsRealtimeService({
    required AppConfig config,
    required AuthState authState,
    Future<RefreshOutcome> Function()? sessionRefresh,
    void Function()? onAuthRejected,
  }) : _stream = SocketNotificationsStream(
          baseUrl: config.apiBaseUrl,
          authState: authState,
          sessionRefresh: sessionRefresh,
          onAuthRejected: onAuthRejected,
        );

  final SocketNotificationsStream _stream;

  StreamSubscription<int>? _unreadSub;
  StreamSubscription<UserNotification>? _newSub;
  StreamSubscription<UserNotification>? _updatedSub;

  final StreamController<UserNotification> _prependController =
      StreamController<UserNotification>.broadcast();
  final StreamController<UserNotification> _updatedController =
      StreamController<UserNotification>.broadcast();

  Stream<UserNotification> get prependItems => _prependController.stream;
  Stream<UserNotification> get updatedItems => _updatedController.stream;

  void start() {
    // Subscribe to streams BEFORE [connect] so any synchronous replay (and
    // the first inbound payload after the handshake) is captured.
    _unreadSub?.cancel();
    _newSub?.cancel();
    _updatedSub?.cancel();
    _unreadSub = _stream.unreadCounts.listen(_onUnreadFromSocket);
    _newSub = _stream.newNotifications.listen(_onNewNotification);
    _updatedSub = _stream.updatedNotifications.listen(_onUpdatedNotification);
    _stream.connect();
  }

  /// Should be called from [WidgetsBindingObserver.didChangeAppLifecycleState]
  /// on [AppLifecycleState.resumed] so we re-open dropped TCP connections.
  void resume() => _stream.resume();

  void stop() {
    _unreadSub?.cancel();
    _newSub?.cancel();
    _updatedSub?.cancel();
    _unreadSub = null;
    _newSub = null;
    _updatedSub = null;
    _stream.disconnect();
  }

  void _onUnreadFromSocket(int count) {
    publishNotificationsUnreadCount(count);
  }

  void _onNewNotification(UserNotification item) {
    _prependController.add(item);
    // List refresh only — unread count comes from notification.new unreadCount
    // (emitted before this item on the socket) or FCM unreadCount payload.
    bumpNotificationsInboxRefreshTick();
  }

  void _onUpdatedNotification(UserNotification item) {
    _updatedController.add(item);
  }

  void dispose() {
    stop();
    _prependController.close();
    _updatedController.close();
    _stream.dispose();
  }
}
