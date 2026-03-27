import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'chisto_default',
      'Chisto Notifications',
      description: 'Default notification channel for Chisto.mk',
      importance: Importance.high,
    );

    if (Platform.isAndroid) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
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
    final RemoteNotification? notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
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
