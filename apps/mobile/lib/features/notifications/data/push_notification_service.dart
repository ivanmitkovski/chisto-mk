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
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:chisto_mobile/features/notifications/data/notification_inbox_refresh.dart';
import 'package:chisto_mobile/features/notifications/data/push_background_pending_store.dart';
import 'package:chisto_mobile/features/notifications/data/event_chat_foreground_scope.dart';
import 'package:chisto_mobile/features/notifications/data/event_chat_local_notification_presenter.dart';
import 'package:chisto_mobile/features/notifications/data/event_chat_notification_details.dart';
import 'package:chisto_mobile/features/notifications/data/event_chat_push_reply_service.dart';
import 'package:chisto_mobile/features/notifications/data/push_notification_payload.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:chisto_mobile/core/bootstrap/cold_start_coordinator.dart';
import 'package:chisto_mobile/core/logging/app_log.dart';

/// In-app rationale dialog was shown (Allow or Not now).
const String kPushPermissionRationaleSeenKey = 'push_permission_rationale_seen_v1';

/// Last time the user denied the OS notification sheet (7-day re-prompt cooldown).
const String kPushPermissionDeniedAtKey = 'push_permission_denied_at_v1';

/// @deprecated Use [kPushPermissionRationaleSeenKey]; kept for migration only.
const String kPushOsPermissionFlowCompletedKey = 'push_os_permission_flow_completed_v1';

/// Whether the process is running on the iOS Simulator (not a physical device).
bool get isRunningOnIosSimulator =>
    Platform.isIOS &&
    Platform.environment.containsKey('SIMULATOR_DEVICE_NAME');

class PushNotificationService {
  PushNotificationService({
    required NotificationsRepository repository,
    required bool Function() isAuthenticated,
  })  : _repository = repository,
        _isAuthenticated = isAuthenticated;

  final NotificationsRepository _repository;
  final bool Function() _isAuthenticated;
  bool _tokenRefreshListenerAttached = false;
  StreamSubscription<RemoteMessage>? _firebaseOnMessageSub;
  StreamSubscription<RemoteMessage>? _firebaseOnMessageOpenedAppSub;
  StreamSubscription<String>? _firebaseOnTokenRefreshSub;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _localNotificationsInitialized = false;
  EventChatNotificationDetails? _eventChatNotificationDetails;
  bool _timezoneInitialized = false;
  static const String _organizerEndSoonChannelId = 'chisto_organizer_cleanup_ending_soon';
  bool _initialized = false;
  bool _firebaseReady = false;
  String? _lastInitReason;
  bool get isInitialized => _initialized;
  bool get isFirebaseReady => _firebaseReady;
  String? get lastInitReason => _lastInitReason;

  String? _currentToken;
  String? _lastRegisteredToken;
  Future<void>? _fetchAndRegisterInFlight;
  final Map<String, Future<void>> _inFlightRegisters = <String, Future<void>>{};
  String? get currentToken => _currentToken;

  final StreamController<RemoteMessage> _foregroundMessageController =
      StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get foregroundMessages =>
      _foregroundMessageController.stream;

  final StreamController<RemoteMessage> _notificationTapController =
      StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get notificationTaps =>
      _notificationTapController.stream;

  final StreamController<Map<String, dynamic>> _localNotificationTapController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get localNotificationTaps =>
      _localNotificationTapController.stream;

  /// Wires Firebase, local notifications, handlers, and token refresh.
  /// Does **not** show the OS permission dialog — call [requestSystemNotificationPermission]
  /// after an in-app rationale (see [kPushPermissionRationaleSeenKey] in [main.dart]).
  Future<void> initialize({Locale? appLanguageOverride}) async {
    if (_initialized) return;
    _initialized = true;

    await _initLocalNotifications(appLanguageOverride: appLanguageOverride);
    await _consumeLocalNotificationLaunchReply();

    if (Firebase.apps.isEmpty) {
      _firebaseReady = false;
      _lastInitReason = 'firebase_not_initialized';
      if (kDebugMode) {
        AppLog.verbose('[Push] Firebase not initialized. Running in local-only mode.');
      }
      return;
    }
    _firebaseReady = true;
    _lastInitReason = 'ok';

    await _configureHandlers();
    await _setIosForegroundPresentationOptions();
    _attachTokenRefreshListener();
    await _fetchAndRegisterTokenIfAuthenticated();
  }

  /// Re-fetches the FCM token and registers it with the API when the user has a session.
  /// Call after sign-in, OTP verify, or successful session restore (not only from [initialize]).
  Future<void> syncDeviceTokenWithBackend() async {
    if (!_firebaseReady) return;
    if (!_isAuthenticated()) return;
    await _fetchAndRegisterTokenIfAuthenticated();
  }

  /// Re-applies iOS foreground presentation options (no token API call).
  Future<void> ensureForegroundPresentationReady() async {
    if (!_firebaseReady) return;
    await _setIosForegroundPresentationOptions();
  }

  /// Ensures iOS foreground presentation and registers the FCM token once per token value.
  Future<void> ensureNotificationDeliveryReady() async {
    if (!_firebaseReady) return;
    await ensureForegroundPresentationReady();
    await syncDeviceTokenWithBackend();
  }

  /// Current OS notification authorization (requires Firebase).
  Future<AuthorizationStatus> notificationAuthorizationStatus() async {
    if (!_firebaseReady) {
      return AuthorizationStatus.notDetermined;
    }
    final NotificationSettings settings =
        await FirebaseMessaging.instance.getNotificationSettings();
    return settings.authorizationStatus;
  }

  Future<NotificationSettings?> getOsNotificationSettings() async {
    if (!_firebaseReady) return null;
    return FirebaseMessaging.instance.getNotificationSettings();
  }

  /// True when the user can receive visible alert banners (not just a silent FCM token).
  Future<bool> hasUsableAlertPermission() async {
    final NotificationSettings? settings = await getOsNotificationSettings();
    if (settings == null) return false;
    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      return false;
    }
    if (Platform.isAndroid) {
      return await Permission.notification.isGranted;
    }
    return settings.alert == AppleNotificationSetting.enabled;
  }

  /// Whether we should show the in-app rationale and system permission sheet.
  Future<bool> shouldPromptForNotificationPermission() async {
    final NotificationSettings? settings = await getOsNotificationSettings();
    if (settings == null) return false;
    switch (settings.authorizationStatus) {
      case AuthorizationStatus.notDetermined:
      case AuthorizationStatus.provisional:
        return true;
      case AuthorizationStatus.authorized:
        return settings.alert != AppleNotificationSetting.enabled;
      case AuthorizationStatus.denied:
        return false;
    }
  }

  /// Requests OS notification permission when alerts are not yet enabled.
  Future<void> requestNotificationPermissionIfNeeded() async {
    if (!await shouldPromptForNotificationPermission()) return;
    await requestSystemNotificationPermission();
  }

  /// `true` when the system notification prompt has never been shown.
  Future<bool> isOsNotificationPermissionUndetermined() async {
    return await notificationAuthorizationStatus() ==
        AuthorizationStatus.notDetermined;
  }

  /// Android 13+ [POST_NOTIFICATIONS] and iOS/macOS alert permission via FCM.
  Future<void> requestSystemNotificationPermission() async {
    if (!_firebaseReady) return;
    if (Platform.isAndroid) {
      final PermissionStatus status = await Permission.notification.request();
      if (kDebugMode) {
        AppLog.verbose('[Push] Android POST_NOTIFICATIONS: $status');
      }
    }
    await _requestOsNotificationPermission();
    await _fetchAndRegisterTokenIfAuthenticated();
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
      AndroidNotificationChannel(
        'chisto_reports',
        strings.pushChannelReportsName,
        description: strings.pushChannelReportsDescription,
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        'chisto_events',
        strings.pushChannelEventsName,
        description: strings.pushChannelEventsDescription,
        importance: Importance.high,
      ),
      AndroidNotificationChannel(
        'chisto_social',
        strings.pushChannelSocialName,
        description: strings.pushChannelSocialDescription,
        importance: Importance.defaultImportance,
      ),
      AndroidNotificationChannel(
        'chisto_system',
        strings.pushChannelSystemName,
        description: strings.pushChannelSystemDescription,
        importance: Importance.defaultImportance,
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

    _eventChatNotificationDetails = EventChatNotificationDetails(
      androidChannel: PushNotificationPayload.resolveAndroidChannel('EVENT_CHAT'),
      replyActionTitle: strings.eventChatPushReplyAction,
      replyInputLabel: strings.eventChatPushReplyPlaceholder,
    );

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: EventChatNotificationDetails.darwinCategories(
        replyTitle: strings.eventChatPushReplyAction,
        replyButtonTitle: strings.eventChatPushReplyButton,
        replyPlaceholder: strings.eventChatPushReplyPlaceholder,
      ),
    );

    await _localNotifications.initialize(
      InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final bool handledReply = await EventChatPushReplyService.handleNotificationResponse(
          response,
          mainIsolate: true,
        );
        if (handledReply) {
          return;
        }
        final Map<String, dynamic>? data =
            _decodeNotificationPayload(response.payload);
        if (data != null) {
          _localNotificationTapController.add(data);
        }
      },
      onDidReceiveBackgroundNotificationResponse:
          onEventChatPushBackgroundNotificationResponse,
    );
    _localNotificationsInitialized = true;
  }

  Future<void> _consumeLocalNotificationLaunchReply() async {
    final NotificationAppLaunchDetails? details =
        await _localNotifications.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp != true) {
      return;
    }
    final NotificationResponse? response = details?.notificationResponse;
    if (response == null) {
      return;
    }
    final bool handledReply = await EventChatPushReplyService.handleNotificationResponse(
      response,
      mainIsolate: true,
    );
    if (handledReply) {
      return;
    }
    final Map<String, dynamic>? data = _decodeNotificationPayload(response.payload);
    if (data != null) {
      _localNotificationTapController.add(data);
    }
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
        AppLog.verbose('[Push] Organizer end-soon schedule failed: $e');
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
        AppLog.verbose('[Push] Organizer end-soon cancel failed: $e');
      }
    }
  }

  Future<void> _requestOsNotificationPermission() async {
    if (Platform.isIOS) {
      final IOSFlutterLocalNotificationsPlugin? iosPlugin =
          _localNotifications.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    NotificationSettings settings =
        await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
      settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    }
    if (kDebugMode) {
      AppLog.verbose(
        '[Push] Permission: ${settings.authorizationStatus}, '
        'alert: ${settings.alert}, badge: ${settings.badge}, sound: ${settings.sound}',
      );
    }

    await _setIosForegroundPresentationOptions();
  }

  Future<void> _setIosForegroundPresentationOptions() async {
    if (!Platform.isIOS) return;
    // Foreground banners use flutter_local_notifications (one code path). FCM only
    // updates the icon badge from APNS so we do not get duplicate iOS banners.
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: true,
      sound: false,
    );
  }

  Future<void> _configureHandlers() async {
    await teardownFirebaseListeners();
    _firebaseOnMessageSub = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        AppLog.verbose('[Push] Foreground message: ${message.messageId}');
      }
      _foregroundMessageController.add(message);
      unawaited(_presentForegroundNotification(message));
    });

    _firebaseOnMessageOpenedAppSub = FirebaseMessaging.onMessageOpenedApp.listen(
      (RemoteMessage message) {
        if (kDebugMode) {
          AppLog.verbose('[Push] Opened from background: ${message.messageId}');
        }
        _notificationTapController.add(message);
      },
    );

    // Cold-start tap is queued via [consumePendingLaunchNotification] + [ColdStartCoordinator].
  }

  /// Cancels FCM stream listeners (logout / re-init). Required for Wave 9 listener ownership.
  Future<void> teardownFirebaseListeners() async {
    await _firebaseOnMessageSub?.cancel();
    _firebaseOnMessageSub = null;
    await _firebaseOnMessageOpenedAppSub?.cancel();
    _firebaseOnMessageOpenedAppSub = null;
    await _firebaseOnTokenRefreshSub?.cancel();
    _firebaseOnTokenRefreshSub = null;
    _tokenRefreshListenerAttached = false;
  }

  /// Call after session restore on cold start (splash / initial route).
  Future<void> consumePendingLaunchNotification() async {
    if (!_firebaseReady) return;

    RemoteMessage? initialMessage;
    try {
      initialMessage = await FirebaseMessaging.instance
          .getInitialMessage()
          .timeout(const Duration(seconds: 2));
    } on Object {
      initialMessage = null;
    }
    if (initialMessage != null) {
      ColdStartCoordinator.instance.queueColdStartPush(initialMessage);
    }

    final PendingPushDrainResult pending =
        await PushBackgroundPendingStore.drainPending();
    if (pending.unreadCount != null) {
      publishNotificationsUnreadCount(pending.unreadCount!);
    }
    if (pending.inboxBump) {
      bumpNotificationsInboxRefreshTick();
    }
    final Map<String, dynamic>? tap = pending.tapPayload;
    if (initialMessage == null && tap != null && tap.isNotEmpty) {
      _localNotificationTapController.add(tap);
    }
  }

  Future<void> _presentForegroundNotification(RemoteMessage message) async {
    final String? type = message.data['type'] as String?;
    if (type == 'EVENT_CHAT') {
      final String? eventId = message.data['eventId'] as String?;
      if (eventId != null &&
          eventId.isNotEmpty &&
          EventChatForegroundScope.instance.isViewingEvent(eventId)) {
        if (kDebugMode) {
          AppLog.verbose('[Push] Foreground chat banner suppressed (active chat)');
        }
        return;
      }
    }
    if (!PushNotificationPayload.shouldPresentForegroundBanner(message)) {
      if (kDebugMode) {
        AppLog.verbose(
          '[Push] Foreground banner suppressed '
          '(kind=${message.data['kind']}, messageId=${message.messageId})',
        );
      }
      return;
    }
    if (!await hasUsableAlertPermission()) {
      if (kDebugMode) {
        AppLog.verbose('[Push] Foreground banner skipped: alert permission off');
      }
      return;
    }
    await _showForegroundBanner(message);
  }

  Future<void> _showForegroundBanner(RemoteMessage message) async {
    await _initLocalNotifications();

    final String? type = message.data['type'] as String?;
    if (type == 'EVENT_CHAT' && _eventChatNotificationDetails != null) {
      final Locale effectiveLocale = resolveAppLocale(
        override: null,
        platformLocales: PlatformDispatcher.instance.locales,
      );
      final AppLocalizations strings = lookupAppLocalizations(effectiveLocale);
      await EventChatLocalNotificationPresenter.show(
        _localNotifications,
        message: message,
        eventChatDetails: _eventChatNotificationDetails!,
        strings: strings,
      );
      return;
    }

    final ({String? title, String? body}) resolved =
        PushNotificationPayload.resolveTitleBody(message);
    final String? title = resolved.title;
    final String? body = resolved.body;
    if (title == null || title.isEmpty || body == null || body.isEmpty) {
      return;
    }

    final AndroidChannelInfo ch = PushNotificationPayload.resolveAndroidChannel(type);
    final String? notificationId = message.data['notificationId'] as String?;
    final int androidId = notificationId != null && notificationId.isNotEmpty
        ? notificationId.hashCode & 0x3fffffff
        : (message.messageId?.hashCode ?? message.hashCode) & 0x3fffffff;
    try {
      await _localNotifications.show(
        androidId,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            ch.id,
            ch.name,
            channelDescription: ch.description,
            importance: ch.importance,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: PushNotificationPayload.encodePayload(message.data),
      );
    } on Object catch (e) {
      if (kDebugMode) {
        AppLog.verbose('[Push] Foreground show failed: $e');
      }
    }
  }

  @visibleForTesting
  static ({String? title, String? body}) resolveNotificationTitleBodyForTest(
    RemoteMessage message,
  ) =>
      PushNotificationPayload.resolveTitleBody(message);

  @visibleForTesting
  static String? encodeNotificationPayloadForTest(Map<String, dynamic> data) =>
      PushNotificationPayload.encodePayload(data);

  @visibleForTesting
  static Map<String, dynamic>? decodeNotificationPayloadForTest(String? raw) =>
      PushNotificationPayload.decodePayload(raw);

  Map<String, dynamic>? _decodeNotificationPayload(String? raw) =>
      PushNotificationPayload.decodePayload(raw);

  void _attachTokenRefreshListener() {
    if (_tokenRefreshListenerAttached) return;
    _tokenRefreshListenerAttached = true;
    unawaited(_firebaseOnTokenRefreshSub?.cancel());
    _firebaseOnTokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen((String token) async {
      _currentToken = token;
      if (!_isAuthenticated()) return;
      await _registerToken(token);
    });
  }

  /// On iOS, FCM requires a valid APNS token before [FirebaseMessaging.getToken].
  Future<String?> _resolveFcmToken() async {
    if (Platform.isIOS) {
      final String? apnsToken = await _waitForApnsToken();
      if (apnsToken == null) {
        return null;
      }
    }
    return FirebaseMessaging.instance.getToken();
  }

  Future<String?> _waitForApnsToken({int maxAttempts = 8}) async {
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final String? apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      if (apnsToken != null) {
        return apnsToken;
      }
      if (attempt < maxAttempts - 1) {
        await Future<void>.delayed(Duration(milliseconds: 250 * (attempt + 1)));
      }
    }
    return null;
  }

  Future<void> _fetchAndRegisterTokenIfAuthenticated() async {
    if (_fetchAndRegisterInFlight != null) {
      return _fetchAndRegisterInFlight;
    }
    final Future<void> work = _fetchAndRegisterTokenIfAuthenticatedImpl();
    _fetchAndRegisterInFlight = work;
    try {
      await work;
    } finally {
      if (identical(_fetchAndRegisterInFlight, work)) {
        _fetchAndRegisterInFlight = null;
      }
    }
  }

  Future<void> _fetchAndRegisterTokenIfAuthenticatedImpl() async {
    if (!_isAuthenticated()) return;
    try {
      final String? token = await _resolveFcmToken();
      if (token == null) {
        if (kDebugMode && Platform.isIOS) {
          if (isRunningOnIosSimulator) {
            AppLog.verbose(
              '[Push] FCM token skipped on iOS Simulator: APNS is usually '
              'unavailable here. Add ios/Runner/GoogleService-Info.plist, '
              'allow notifications, and test FCM on a physical iPhone. '
              'Foreground local banners still work in the simulator.',
            );
          } else {
            AppLog.verbose(
              '[Push] FCM token deferred: APNS not available yet. '
              'Allow notifications in Settings, ensure GoogleService-Info.plist '
              'is in ios/Runner, and upload the APNs .p8 key in Firebase.',
            );
          }
        }
        return;
      }
      _currentToken = token;
      await _registerToken(token);
    } catch (e) {
      if (kDebugMode) {
        final String message = e.toString();
        if (Platform.isIOS &&
            message.contains('apns-token-not-set')) {
          AppLog.verbose(
            '[Push] FCM token deferred: APNS not set. '
            'Allow notifications or use a physical iOS device.',
          );
        } else {
          AppLog.verbose('[Push] Token refresh error: $e');
        }
      }
    }
  }

  Future<void> _registerToken(
    String token, {
    String? appVersionOverride,
  }) async {
    if (!_isAuthenticated()) return;
    if (_lastRegisteredToken == token) {
      return;
    }
    final Future<void>? inFlight = _inFlightRegisters[token];
    if (inFlight != null) {
      return inFlight;
    }
    final Future<void> work = _registerTokenImpl(
      token,
      appVersionOverride: appVersionOverride,
    );
    _inFlightRegisters[token] = work;
    try {
      await work;
    } finally {
      if (identical(_inFlightRegisters[token], work)) {
        _inFlightRegisters.remove(token);
      }
    }
  }

  Future<void> _registerTokenImpl(
    String token, {
    String? appVersionOverride,
  }) async {
    if (!_isAuthenticated()) return;
    if (_lastRegisteredToken == token) {
      return;
    }
    try {
      final String appVersion = appVersionOverride ??
          (await PackageInfo.fromPlatform()).version;
      final Locale locale = resolveAppLocale(
        override: null,
        platformLocales: PlatformDispatcher.instance.locales,
      );
      await _repository.registerDeviceToken(
        token: token,
        platform: Platform.isIOS ? 'IOS' : 'ANDROID',
        appVersion: appVersion,
        locale: locale.languageCode,
      );
      _lastRegisteredToken = token;
      if (kDebugMode) {
        AppLog.verbose('[Push] Device token registered with API.');
      }
    } on AppError catch (e) {
      if (kDebugMode &&
          e.code != 'UNAUTHORIZED' &&
          e.code != 'DEVICE_TOKEN_IN_USE') {
        AppLog.verbose('[Push] Token registration error: ${e.code}');
      }
    } catch (e) {
      if (kDebugMode) {
        AppLog.verbose('[Push] Token registration error: $e');
      }
    }
  }

  /// Drops the cached FCM token locally without calling the API.
  ///
  /// Use when the session is already invalid ([invalidateLocalSession],
  /// failed restore); server-side token rows expire via TTL/revocation.
  void clearLocalToken() {
    _currentToken = null;
    _lastRegisteredToken = null;
  }

  /// Best-effort server unregister while the user session is still valid (sign-out).
  Future<void> unregisterCurrentToken() async {
    if (!_firebaseReady) return;
    final String? token = _currentToken;
    if (token == null) return;
    try {
      await _repository.unregisterDeviceToken(token);
      if (kDebugMode) {
        AppLog.verbose('[Push] Token unregistered');
      }
    } on AppError catch (e) {
      if (kDebugMode && !_isBenignUnregisterFailure(e)) {
        AppLog.verbose('[Push] Token unregister error: ${e.code}');
      }
    } catch (e) {
      if (kDebugMode && !_isBenignUnregisterFailure(e)) {
        AppLog.verbose('[Push] Token unregister error: $e');
      }
    } finally {
      _currentToken = null;
      _lastRegisteredToken = null;
    }
  }

  @visibleForTesting
  Future<void> registerTokenForTest(String token) =>
      _registerToken(token, appVersionOverride: 'test');

  @visibleForTesting
  String? get lastRegisteredTokenForTest => _lastRegisteredToken;

  static bool _isBenignUnregisterFailure(Object error) {
    if (error is AppError) {
      return error.code == 'UNAUTHORIZED' || error.code == 'SESSION_REVOKED';
    }
    final String message = error.toString();
    return message.contains('SESSION_REVOKED') ||
        message.contains('UNAUTHORIZED');
  }

  void dispose() {
    unawaited(teardownFirebaseListeners());
    _foregroundMessageController.close();
    _notificationTapController.close();
    _localNotificationTapController.close();
  }
}
