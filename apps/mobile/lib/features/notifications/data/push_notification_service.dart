import 'dart:async';
import 'dart:io';
import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:chisto_mobile/core/l10n/app_locale_resolution.dart';
import 'package:chisto_mobile/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';

/// SharedPreferences key: user completed push rationale + OS prompt flow (allow or dismiss).
const String kPushOsPermissionFlowCompletedKey = 'push_os_permission_flow_completed_v1';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    debugPrint('[Push] Background message: ${message.messageId}');
  }
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

  /// Wires Firebase, local notifications, handlers, and token refresh.
  /// Does **not** show the OS permission dialog — call [requestSystemNotificationPermission]
  /// after an in-app rationale (see [kPushOsPermissionFlowCompletedKey] in [main.dart]).
  Future<void> initialize({Locale? appLanguageOverride}) async {
    if (_initialized) return;
    _initialized = true;

    await _initLocalNotifications(appLanguageOverride: appLanguageOverride);

    if (Firebase.apps.isEmpty) {
      _firebaseReady = false;
      _lastInitReason = 'firebase_not_initialized';
      if (kDebugMode) {
        debugPrint('[Push] Firebase not initialized. Running in local-only mode.');
      }
      return;
    }
    _firebaseReady = true;
    _lastInitReason = 'ok';

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await _configureHandlers();
    await _refreshToken();
  }

  /// Android 13+ [POST_NOTIFICATIONS] and iOS/macOS alert permission via FCM.
  Future<void> requestSystemNotificationPermission() async {
    if (!_firebaseReady) return;
    if (Platform.isAndroid) {
      final PermissionStatus status = await Permission.notification.request();
      if (kDebugMode) {
        debugPrint('[Push] Android POST_NOTIFICATIONS: $status');
      }
    }
    await _requestOsNotificationPermission();
  }

  Future<void> _initLocalNotifications({Locale? appLanguageOverride}) async {
    if (_localNotificationsInitialized) {
      return;
    }
    final Locale effectiveLocale = resolveAppLocale(
      override: appLanguageOverride,
      platformLocales: PlatformDispatcher.instance.locales,
    );
    final AppLocalizations strings = lookupAppLocalizations(effectiveLocale);
    final List<AndroidNotificationChannel> channels = <AndroidNotificationChannel>[
      AndroidNotificationChannel(
        'chisto_default',
        strings.pushChannelDefaultName,
        description: strings.pushChannelDefaultDescription,
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        'chisto_event_chat',
        strings.eventChatPushChannelName,
        description: strings.eventChatPushChannelDescription,
        importance: Importance.high,
      ),
      const AndroidNotificationChannel(
        'chisto_reports',
        'Report Updates',
        description: 'Report status changes and nearby pollution reports',
        importance: Importance.high,
      ),
      const AndroidNotificationChannel(
        'chisto_events',
        'Cleanup Events',
        description: 'Cleanup event reminders and updates',
        importance: Importance.high,
      ),
      const AndroidNotificationChannel(
        'chisto_social',
        'Social Activity',
        description: 'Upvotes, comments, and community interactions',
        importance: Importance.defaultImportance,
      ),
      const AndroidNotificationChannel(
        'chisto_system',
        'System',
        description: 'System announcements and achievements',
        importance: Importance.low,
      ),
    ];

    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? android =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      for (final AndroidNotificationChannel c in channels) {
        await android?.createNotificationChannel(c);
      }
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
        if (kDebugMode) {
          debugPrint('[Push] Local notification tapped: ${response.payload}');
        }
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
      if (kDebugMode) {
        debugPrint('[Push] Organizer end-soon schedule failed: $e');
      }
    }
  }

  Future<void> cancelOrganizerCleanupEndingSoon(String eventId) async {
    try {
      await _initLocalNotifications();
      final int id = _organizerEndSoonNotificationId(eventId);
      await _localNotifications.cancel(id);
    } on Object catch (e) {
      if (kDebugMode) {
        debugPrint('[Push] Organizer end-soon cancel failed: $e');
      }
    }
  }

  Future<void> _requestOsNotificationPermission() async {
    final NotificationSettings settings =
        await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    if (kDebugMode) {
      debugPrint('[Push] Permission: ${settings.authorizationStatus}');
    }

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
      if (kDebugMode) {
        debugPrint('[Push] Foreground message: ${message.messageId}');
      }
      _foregroundMessageController.add(message);
      _showLocalNotification(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        debugPrint('[Push] Opened from background: ${message.messageId}');
      }
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

    final _AndroidChannelInfo ch = _resolveAndroidChannel(type);
    _localNotifications.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          ch.id,
          ch.name,
          channelDescription: ch.description,
          importance: ch.importance,
          priority: Priority.high,
          groupKey: type == 'EVENT_CHAT' ? 'event_chat' : null,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          threadIdentifier: type == 'EVENT_CHAT'
              ? (message.data['eventId'] as String? ?? 'event_chat')
              : null,
        ),
      ),
      payload: message.data['notificationId'] as String?,
    );
  }

  static _AndroidChannelInfo _resolveAndroidChannel(String? type) {
    switch (type) {
      case 'EVENT_CHAT':
        return const _AndroidChannelInfo(
          'chisto_event_chat', 'Event Chat', 'Messages on cleanup events you joined', Importance.high);
      case 'REPORT_STATUS':
      case 'NEARBY_REPORT':
        return const _AndroidChannelInfo(
          'chisto_reports', 'Report Updates', 'Report status changes and nearby pollution reports', Importance.high);
      case 'CLEANUP_EVENT':
        return const _AndroidChannelInfo(
          'chisto_events', 'Cleanup Events', 'Cleanup event reminders and updates', Importance.high);
      case 'UPVOTE':
      case 'COMMENT':
        return const _AndroidChannelInfo(
          'chisto_social', 'Social Activity', 'Upvotes, comments, and community interactions', Importance.defaultImportance);
      case 'SYSTEM':
      case 'ACHIEVEMENT':
      case 'WELCOME':
        return const _AndroidChannelInfo(
          'chisto_system', 'System', 'System announcements and achievements', Importance.low);
      default:
        return const _AndroidChannelInfo(
          'chisto_default', 'Chisto Notifications', 'Default notification channel for Chisto.mk', Importance.high);
    }
  }

  Future<void> _refreshToken() async {
    try {
      _currentToken = await FirebaseMessaging.instance.getToken();
      if (_currentToken != null) {
        await _registerToken(_currentToken!);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Push] Token refresh error: $e');
      }
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
      if (kDebugMode) {
        debugPrint('[Push] Token registered (debug only; value never logged).');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Push] Token registration error: $e');
      }
    }
  }

  Future<void> unregisterCurrentToken() async {
    if (!_firebaseReady) return;
    if (_currentToken == null) return;
    try {
      await _repository.unregisterDeviceToken(_currentToken!);
      if (kDebugMode) {
        debugPrint('[Push] Token unregistered');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Push] Token unregister error: $e');
      }
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

class _AndroidChannelInfo {
  const _AndroidChannelInfo(this.id, this.name, this.description, this.importance);
  final String id;
  final String name;
  final String description;
  final Importance importance;
}
