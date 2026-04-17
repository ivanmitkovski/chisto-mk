import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:chisto_mobile/features/notifications/domain/repositories/notifications_repository.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[Push] Background message: ${message.messageId}');
}

class PushNotificationService {
  PushNotificationService({required NotificationsRepository repository})
      : _repository = repository;

  final NotificationsRepository _repository;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _localNotificationsInitialized = false;
  bool _timezoneInitialized = false;
  static const String _organizerEndSoonChannelId = 'chisto_organizer_cleanup_ending_soon';
  bool _initialized = false;
  bool _firebaseReady = false;
  String? _lastInitReason;
  bool get isInitialized => _initialized;
  bool get isFirebaseReady => _firebaseReady;
  String? get lastInitReason => _lastInitReason;

  String? _currentToken;
  String? get currentToken => _currentToken;

  final StreamController<RemoteMessage> _foregroundMessageController =
      StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get foregroundMessages =>
      _foregroundMessageController.stream;

  final StreamController<RemoteMessage> _notificationTapController =
      StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get notificationTaps =>
      _notificationTapController.stream;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _initLocalNotifications();

    if (Firebase.apps.isEmpty) {
      _firebaseReady = false;
      _lastInitReason = 'firebase_not_initialized';
      debugPrint('[Push] Firebase not initialized. Running in local-only mode.');
      return;
    }
    _firebaseReady = true;
    _lastInitReason = 'ok';

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await _requestPermission();
    await _configureHandlers();
    await _refreshToken();
  }

  Future<void> _initLocalNotifications() async {
    if (_localNotificationsInitialized) {
      return;
    }
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'chisto_default',
      'Chisto Notifications',
      description: 'Default notification channel for Chisto.mk',
      importance: Importance.high,
    );
    const AndroidNotificationChannel chatChannel = AndroidNotificationChannel(
      'chisto_event_chat',
      'Event chat',
      description: 'Messages on cleanup events you joined',
      importance: Importance.high,
    );

    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? android =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(channel);
      await android?.createNotificationChannel(chatChannel);
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('[Push] Local notification tapped: ${response.payload}');
      },
    );
    _localNotificationsInitialized = true;
  }

  Future<void> _ensureTimezoneInitialized() async {
    if (_timezoneInitialized) {
      return;
    }
    tzdata.initializeTimeZones();
    _timezoneInitialized = true;
  }

  int _organizerEndSoonNotificationId(String eventId) {
    final String hex = eventId.replaceAll('-', '');
    if (hex.length >= 8) {
      return int.parse(hex.substring(0, 8), radix: 16);
    }
    return eventId.hashCode & 0x3fffffff;
  }

  Future<void> scheduleOrganizerCleanupEndingSoon({
    required String eventId,
    required DateTime fireAtUtc,
    required String title,
    required String body,
    required String channelName,
    required String channelDescription,
  }) async {
    try {
      await _initLocalNotifications();
      await _ensureTimezoneInitialized();
      final DateTime utcNow = DateTime.now().toUtc();
      if (!fireAtUtc.toUtc().isAfter(utcNow.add(const Duration(seconds: 2)))) {
        return;
      }
      if (Platform.isAndroid) {
        final AndroidFlutterLocalNotificationsPlugin? android =
            _localNotifications.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await android?.createNotificationChannel(
          AndroidNotificationChannel(
            _organizerEndSoonChannelId,
            channelName,
            description: channelDescription,
            importance: Importance.defaultImportance,
          ),
        );
      }
      final int id = _organizerEndSoonNotificationId(eventId);
      final tz.TZDateTime scheduled =
          tz.TZDateTime.from(fireAtUtc.toUtc(), tz.UTC);
      await _localNotifications.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _organizerEndSoonChannelId,
            channelName,
            channelDescription: channelDescription,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: eventId,
      );
    } on Object catch (e) {
      debugPrint('[Push] Organizer end-soon schedule failed: $e');
    }
  }

  Future<void> cancelOrganizerCleanupEndingSoon(String eventId) async {
    try {
      await _initLocalNotifications();
      final int id = _organizerEndSoonNotificationId(eventId);
      await _localNotifications.cancel(id);
    } on Object catch (e) {
      debugPrint('[Push] Organizer end-soon cancel failed: $e');
    }
  }

  Future<void> _requestPermission() async {
    final NotificationSettings settings =
        await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('[Push] Permission: ${settings.authorizationStatus}');

    if (Platform.isIOS) {
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  Future<void> _configureHandlers() async {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[Push] Foreground message: ${message.messageId}');
      _foregroundMessageController.add(message);
      _showLocalNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[Push] Opened from background: ${message.messageId}');
      _notificationTapController.add(message);
    });

    final RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _notificationTapController.add(initialMessage);
    }
  }

  void _showLocalNotification(RemoteMessage message) {
    final String? type = message.data['type'] as String?;
    final RemoteNotification? notification = message.notification;
    String? title = notification?.title;
    String? body = notification?.body;
    if (type == 'EVENT_CHAT') {
      title ??= message.data['title'] as String?;
      body ??= message.data['messagePreview'] as String? ?? message.data['body'] as String?;
    }
    if (title == null || title.isEmpty || body == null || body.isEmpty) {
      return;
    }

    final bool isChat = type == 'EVENT_CHAT';
    _localNotifications.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          isChat ? 'chisto_event_chat' : 'chisto_default',
          isChat ? 'Event chat' : 'Chisto Notifications',
          channelDescription: isChat
              ? 'Messages on cleanup events you joined'
              : 'Default notification channel for Chisto.mk',
          importance: Importance.high,
          priority: Priority.high,
          groupKey: isChat ? 'event_chat' : null,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          threadIdentifier: isChat ? (message.data['eventId'] as String? ?? 'event_chat') : null,
        ),
      ),
      payload: message.data['notificationId'] as String?,
    );
  }

  Future<void> _refreshToken() async {
    try {
      _currentToken = await FirebaseMessaging.instance.getToken();
      if (_currentToken != null) {
        await _registerToken(_currentToken!);
      }
    } catch (e) {
      debugPrint('[Push] Token refresh error: $e');
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((String token) async {
      _currentToken = token;
      await _registerToken(token);
    });
  }

  Future<void> _registerToken(String token) async {
    try {
      await _repository.registerDeviceToken(
        token: token,
        platform: Platform.isIOS ? 'IOS' : 'ANDROID',
      );
      debugPrint('[Push] Token registered: ${token.substring(0, 12)}...');
    } catch (e) {
      debugPrint('[Push] Token registration error: $e');
    }
  }

  Future<void> unregisterCurrentToken() async {
    if (!_firebaseReady) return;
    if (_currentToken == null) return;
    try {
      await _repository.unregisterDeviceToken(_currentToken!);
      debugPrint('[Push] Token unregistered');
    } catch (e) {
      debugPrint('[Push] Token unregister error: $e');
    }
    _currentToken = null;
  }

  void dispose() {
    _foregroundMessageController.close();
    _notificationTapController.close();
  }

  Future<void> showDebugLocalNotification({
    String title = 'Push preview',
    String body = 'Local preview works. FCM can be enabled later.',
  }) async {
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch % 100000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'chisto_default',
          'Chisto Notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }
}
