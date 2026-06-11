library;

import 'dart:async';
import 'dart:io';
import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:chisto_core/chisto_core.dart';
import 'package:chisto_infrastructure/core/bootstrap/cold_start_coordinator.dart';
import 'package:chisto_infrastructure/core/l10n/app_locale_resolution.dart';
import 'package:chisto_infrastructure/core/logging/app_log.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:feature_auth/feature_auth.dart';
import 'package:feature_notifications/src/data/event_chat_foreground_scope.dart';
import 'package:feature_notifications/src/data/event_chat_local_notification_presenter.dart';
import 'package:feature_notifications/src/data/event_chat_notification_details.dart';
import 'package:feature_notifications/src/data/event_chat_push_reply_service.dart';
import 'package:feature_notifications/src/data/notification_inbox_refresh.dart';
import 'package:feature_notifications/src/data/push_android_channels.dart';
import 'package:feature_notifications/src/data/push_background_pending_store.dart';
import 'package:feature_notifications/src/data/push_notification_payload.dart';
import 'package:feature_notifications/src/domain/repositories/notifications_repository.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

part 'push_notification_local.dart';

/// In-app rationale dialog was shown (Allow or Not now).
const String kPushPermissionRationaleSeenKey =
    'push_permission_rationale_seen_v1';

/// Last time the user denied the OS notification sheet (7-day re-prompt cooldown).
const String kPushPermissionDeniedAtKey = 'push_permission_denied_at_v1';

/// @deprecated Use [kPushPermissionRationaleSeenKey]; kept for migration only.
const String kPushOsPermissionFlowCompletedKey =
    'push_os_permission_flow_completed_v1';

/// Whether the process is running on the iOS Simulator (not a physical device).
bool get isRunningOnIosSimulator =>
    Platform.isIOS && Platform.environment.containsKey('SIMULATOR_DEVICE_NAME');

class PushNotificationService
    with PushNotificationLocal
    implements AuthPushPort {
  PushNotificationService({
    required NotificationsRepository repository,
    required bool Function() isAuthenticated,
    Locale Function()? resolveEffectiveLocale,
  }) : _repository = repository,
       _isAuthenticated = isAuthenticated,
       _resolveEffectiveLocale = resolveEffectiveLocale;

  final NotificationsRepository _repository;
  final bool Function() _isAuthenticated;
  final Locale Function()? _resolveEffectiveLocale;
  void Function(AppError error)? onRegistrationFailure;
  bool _initialized = false;
  String? _lastInitReason;
  bool get isInitialized => _initialized;
  bool get isFirebaseReady => _firebaseReady;
  String? get lastInitReason => _lastInitReason;

  String? _currentToken;
  String? _lastRegisteredToken;
  String? _lastRegisteredLocale;
  Future<void>? _fetchAndRegisterInFlight;
  final Map<String, Future<void>> _inFlightRegisters = <String, Future<void>>{};
  String? get currentToken => _currentToken;

  Stream<RemoteMessage> get foregroundMessages =>
      _foregroundMessageController.stream;

  Stream<RemoteMessage> get notificationTaps =>
      _notificationTapController.stream;

  Stream<Map<String, dynamic>> get localNotificationTaps =>
      _localNotificationTapController.stream;

  /// Wires Firebase, local notifications, handlers, and token refresh.
  /// Does **not** show the OS permission dialog — call [requestSystemNotificationPermission]
  /// after an in-app rationale (see [kPushPermissionRationaleSeenKey] in [main.dart]).
  @override
  Future<void> initialize({Locale? appLanguageOverride}) async {
    if (_initialized) return;
    _initialized = true;

    await _initLocalNotifications(appLanguageOverride: appLanguageOverride);
    await _consumeLocalNotificationLaunchReply();

    if (Firebase.apps.isEmpty) {
      _firebaseReady = false;
      _lastInitReason = 'firebase_not_initialized';
      if (kDebugMode) {
        AppLog.verbose(
          '[Push] Firebase not initialized. Running in local-only mode.',
        );
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
  ///
  /// When [forceLocaleRefresh] is true, re-sends the current token if only the locale changed.
  Future<void> syncDeviceTokenWithBackend({bool forceLocaleRefresh = false}) async {
    if (!_isAuthenticated()) return;
    if (forceLocaleRefresh) {
      final String? token = _currentToken ?? _lastRegisteredToken;
      if (token != null) {
        await _registerToken(token, force: true);
        return;
      }
    }
    if (!_firebaseReady) return;
    await _fetchAndRegisterTokenIfAuthenticated();
  }

  /// Re-applies iOS foreground presentation options (no token API call).
  Future<void> ensureForegroundPresentationReady() async {
    if (!_firebaseReady) return;
    await _setIosForegroundPresentationOptions();
  }

  /// Queues terminated-state FCM taps and drains background push hints.
  Future<void> consumePendingLaunchNotification() =>
      consumePendingLaunchNotificationImpl();

  /// Ensures iOS foreground presentation and registers the FCM token once per token value.
  @override
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
    final NotificationSettings settings = await FirebaseMessaging.instance
        .getNotificationSettings();
    return settings.authorizationStatus;
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
  @override
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

  /// True when the user must open system Settings to re-enable notifications.
  Future<bool> isNotificationPermissionPermanentlyDenied() async {
    if (Platform.isAndroid) {
      return Permission.notification.isPermanentlyDenied;
    }
    final AuthorizationStatus status = await notificationAuthorizationStatus();
    return status == AuthorizationStatus.denied;
  }

  Future<void> _requestOsNotificationPermission() async {
    if (Platform.isIOS) {
      final IOSFlutterLocalNotificationsPlugin? iosPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    NotificationSettings settings = await FirebaseMessaging.instance
        .requestPermission(
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
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: false,
          badge: true,
          sound: false,
        );
  }

  void _attachTokenRefreshListener() {
    if (_tokenRefreshListenerAttached) return;
    _tokenRefreshListenerAttached = true;
    unawaited(_firebaseOnTokenRefreshSub?.cancel());
    _firebaseOnTokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh
        .listen((String token) async {
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
        if (Platform.isIOS && message.contains('apns-token-not-set')) {
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
    bool force = false,
  }) async {
    if (!_isAuthenticated()) return;
    if (!force && _lastRegisteredToken == token && _isLocaleUnchanged()) {
      return;
    }
    final Future<void>? inFlight = _inFlightRegisters[token];
    if (inFlight != null) {
      return inFlight;
    }
    final Future<void> work = _registerTokenImpl(
      token,
      appVersionOverride: appVersionOverride,
      force: force,
    );
    _inFlightRegisters[token] = work;
    try {
      await work;
    } finally {
      if (identical(_inFlightRegisters[token], work)) {
        unawaited(_inFlightRegisters.remove(token));
      }
    }
  }

  Future<void> _registerTokenImpl(
    String token, {
    String? appVersionOverride,
    bool force = false,
  }) async {
    if (!_isAuthenticated()) return;
    final Locale locale = _effectiveLocale();
    final String localeCode = locale.languageCode;
    if (!force &&
        _lastRegisteredToken == token &&
        _lastRegisteredLocale == localeCode) {
      return;
    }
    try {
      final String appVersion =
          appVersionOverride ?? (await PackageInfo.fromPlatform()).version;
      await _repository.registerDeviceToken(
        token: token,
        platform: Platform.isIOS ? 'IOS' : 'ANDROID',
        appVersion: appVersion,
        locale: localeCode,
      );
      _lastRegisteredToken = token;
      _lastRegisteredLocale = localeCode;
      if (kDebugMode) {
        AppLog.verbose('[Push] Device token registered with API.');
      }
    } on AppError catch (e) {
      if (kDebugMode &&
          e.code != 'UNAUTHORIZED' &&
          e.code != 'DEVICE_TOKEN_IN_USE') {
        AppLog.verbose('[Push] Token registration error: ${e.code}');
      }
      if (!_isBenignRegistrationFailure(e)) {
        onRegistrationFailure?.call(e);
      }
    } catch (e) {
      if (kDebugMode) {
        AppLog.verbose('[Push] Token registration error: $e');
      }
      onRegistrationFailure?.call(AppError.unknown(cause: e));
    }
  }

  /// Drops the cached FCM token locally without calling the API.
  ///
  /// Use when the session is already invalid ([invalidateLocalSession],
  /// failed restore); server-side token rows expire via TTL/revocation.
  @override
  void clearLocalToken() {
    _currentToken = null;
    _lastRegisteredToken = null;
    _lastRegisteredLocale = null;
  }

  /// Best-effort server unregister while the user session is still valid (sign-out).
  @override
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
      _lastRegisteredLocale = null;
    }
  }

  Locale _effectiveLocale() {
    final Locale Function()? resolver = _resolveEffectiveLocale;
    if (resolver != null) {
      return resolver();
    }
    return resolveAppLocale(
      override: null,
      platformLocales: PlatformDispatcher.instance.locales,
    );
  }

  bool _isLocaleUnchanged() {
    final String localeCode = _effectiveLocale().languageCode;
    return _lastRegisteredLocale == localeCode;
  }

  @visibleForTesting
  Future<void> registerTokenForTest(
    String token, {
    bool force = false,
  }) async {
    _currentToken = token;
    await _registerToken(
      token,
      appVersionOverride: 'test',
      force: force,
    );
  }

  @visibleForTesting
  String? get lastRegisteredTokenForTest => _lastRegisteredToken;

  @visibleForTesting
  static ({String? title, String? body}) resolveNotificationTitleBodyForTest(
    RemoteMessage message,
  ) => PushNotificationPayload.resolveTitleBody(message);

  @visibleForTesting
  static String? encodeNotificationPayloadForTest(Map<String, dynamic> data) =>
      PushNotificationPayload.encodePayload(data);

  @visibleForTesting
  static Map<String, dynamic>? decodeNotificationPayloadForTest(String? raw) =>
      PushNotificationPayload.decodePayload(raw);

  static bool _isBenignUnregisterFailure(Object error) {
    if (error is AppError) {
      return error.code == 'UNAUTHORIZED' || error.code == 'SESSION_REVOKED';
    }
    final String message = error.toString();
    return message.contains('SESSION_REVOKED') ||
        message.contains('UNAUTHORIZED');
  }

  static bool _isBenignRegistrationFailure(AppError error) {
    return error.code == 'UNAUTHORIZED' ||
        error.code == 'SESSION_REVOKED' ||
        error.code == 'DEVICE_TOKEN_IN_USE';
  }

  void dispose() {
    unawaited(teardownFirebaseListeners());
    _foregroundMessageController.close();
    _notificationTapController.close();
    _localNotificationTapController.close();
  }
}
