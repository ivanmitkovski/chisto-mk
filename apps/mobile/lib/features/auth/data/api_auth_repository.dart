import 'dart:async';
import 'dart:math' as math;

import 'package:chisto_mobile/core/auth/auth_state.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/network/api_client.dart';
import 'package:chisto_mobile/core/storage/secure_token_storage.dart';
import 'package:chisto_mobile/features/auth/data/access_token_expiry.dart';
import 'package:chisto_mobile/features/auth/data/eula_acceptance_store.dart';
import 'package:chisto_mobile/features/auth/data/user_home_location_store.dart';
import 'package:chisto_mobile/features/auth/domain/models/register_result.dart';
import 'package:chisto_mobile/features/auth/domain/refresh_outcome.dart';
import 'package:chisto_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:chisto_mobile/features/notifications/data/push_notification_service.dart';
import 'package:chisto_mobile/features/events/data/chat/outbox/chat_outbox_store.dart';
import 'package:chisto_mobile/features/events/data/events_local_cache.dart';
import 'package:chisto_mobile/features/events/data/field_mode_queue.dart';
import 'package:chisto_mobile/features/events/data/check_in_local_cache.dart';
import 'package:chisto_mobile/features/events/data/discovery_analytics.dart';
import 'package:chisto_mobile/features/events/data/event_feedback_local_cache.dart';
import 'package:chisto_mobile/features/home/data/engagement_outbox_store.dart';
import 'package:chisto_mobile/features/home/data/map_search_recents_store.dart';
import 'package:chisto_mobile/features/notifications/data/pending_chat_reply_store.dart';
import 'package:chisto_mobile/features/notifications/data/push_background_pending_store.dart';
import 'package:chisto_mobile/core/bootstrap/app_bootstrap.dart';
import 'package:chisto_mobile/core/bootstrap/cold_start_coordinator.dart';
import 'package:chisto_mobile/core/logging/app_log.dart';
import 'package:chisto_mobile/core/profile/profile_avatar_sync.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Citizen auth over HTTP — paths align with NestJS `auth/*` controllers in `apps/api`:
/// `POST /auth/register`, `/auth/login`, `/auth/refresh`, `/auth/logout`;
/// `POST /auth/otp/send`, `/auth/otp/verify`,
/// `/auth/password-reset/request`, `/auth/password-reset/verify-code`,
/// `/auth/password-reset/confirm`;
/// `GET`/`PATCH` `/auth/me`, `PATCH /auth/me/password`, `DELETE /auth/me`;
/// multipart `POST`/`DELETE` `/auth/me/avatar`.
const String _keyUserId = 'chisto_user_id';
const String _keyDisplayName = 'chisto_display_name';

/// Parses `/auth/me` or auth `user` organizer certification timestamp.
///
/// Returns null for empty or unparseable values (never throws on bad types).
DateTime? _parseOrganizerCertifiedAtField(dynamic raw) {
  if (raw == null) {
    return null;
  }
  final String s = raw is String ? raw.trim() : raw.toString().trim();
  if (s.isEmpty) {
    return null;
  }
  return DateTime.tryParse(s);
}

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository({
    required ApiClient client,
    required AuthState authState,
    required SecureTokenStorage tokenStorage,
    required SharedPreferences preferences,
    this.pushService,
    ProfileAvatarSync? avatarSync,
  }) : _client = client,
       _authState = authState,
       _tokenStorage = tokenStorage,
       _preferences = preferences,
       _avatarSync = avatarSync ?? const NoOpProfileAvatarSync();

  final ApiClient _client;
  final AuthState _authState;
  final SecureTokenStorage _tokenStorage;
  final SharedPreferences _preferences;
  final ProfileAvatarSync _avatarSync;
  final PushNotificationService? pushService;
  Timer? _proactiveRefreshTimer;

  /// Bumped when sign-in / refresh / OTP verify writes new tokens so an in-flight
  /// [restoreSession] cannot clear the session afterward.
  int _restoreGeneration = 0;

  bool _restoreProfileValidationPending = false;

  /// `false` when the server reports current terms are accepted; `null` until known.
  bool? _requiresTermsAcceptance;

  @override
  bool? get requiresTermsAcceptance => _requiresTermsAcceptance;

  @override
  bool get restoreProfileValidationPending => _restoreProfileValidationPending;

  @override
  bool get isAuthenticated => _authState.isAuthenticated;

  @override
  String? get currentUserId => _authState.userId;

  @override
  String? get accessToken => _authState.accessToken;

  @override
  Future<void> signIn({
    required String phoneNumber,
    required String password,
    bool rememberMe = true,
  }) async {
    final ApiResponse response = await _client.post(
      '/auth/login',
      body: <String, dynamic>{
        'phoneNumber': phoneNumber,
        'password': password,
        'rememberMe': rememberMe,
        'deviceId': await _tokenStorage.deviceId,
      },
    );
    final Map<String, dynamic>? json = response.json;
    if (json == null) throw AppError.unknown();
    await _saveAndNotify(json);
    _scheduleProactiveRefresh();
    unawaited(_initPushAfterAuth());
  }

  @override
  Future<RegisterResult> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    final DateTime acceptedAt = DateTime.now().toUtc();
    final ApiResponse response = await _client.post(
      '/auth/register',
      body: <String, dynamic>{
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'email': email.trim().toLowerCase(),
        'phoneNumber': phoneNumber,
        'password': password,
        'termsAcceptedAt': acceptedAt.toIso8601String(),
        'termsVersion': EulaAcceptanceStore.currentVersion,
        'privacyAcceptedAt': acceptedAt.toIso8601String(),
        'deviceId': await _tokenStorage.deviceId,
      },
    );
    final Map<String, dynamic>? json = response.json;
    if (json == null) throw AppError.unknown();
    final String userId = json['userId']?.toString() ?? '';
    final String phone = json['phoneNumber']?.toString() ?? phoneNumber;
    final int expiresIn = json['otpExpiresIn'] is int
        ? json['otpExpiresIn'] as int
        : 600;
    if (userId.isEmpty) throw AppError.unknown();
    return RegisterResult(
      userId: userId,
      phoneNumber: phone,
      otpExpiresInSeconds: expiresIn,
    );
  }

  @override
  Future<RefreshOutcome> refreshSession() async {
    AppBootstrap.instance.armSuppressSessionExpiredWindow(
      const Duration(seconds: 2),
    );
    try {
      final String? storedRefresh = await _tokenStorage.refreshToken;
      if (storedRefresh == null || storedRefresh.isEmpty) {
        return RefreshOutcome.serverRejected;
      }

      final ApiResponse response = await _client.post(
        '/auth/refresh',
        body: <String, dynamic>{
          'refreshToken': storedRefresh,
          'deviceId': await _tokenStorage.deviceId,
        },
      );
      final Map<String, dynamic>? json = response.json;
      if (json == null) {
        return RefreshOutcome.transient;
      }
      await _saveAndNotify(json);
      _scheduleProactiveRefresh();
      return RefreshOutcome.success;
    } on AppError catch (e) {
      if (e.code == 'UNAUTHORIZED' ||
          e.code == 'INVALID_TOKEN_USER' ||
          e.code == 'SESSION_REVOKED') {
        return RefreshOutcome.serverRejected;
      }
      return RefreshOutcome.transient;
    } on Object {
      return RefreshOutcome.transient;
    }
  }

  @override
  Future<SendOtpResult> requestOtp(String phoneNumberE164) async {
    final ApiResponse response = await _client.post(
      '/auth/otp/send',
      body: <String, dynamic>{'phoneNumber': phoneNumberE164},
    );
    final Map<String, dynamic>? json = response.json;
    if (json == null) throw AppError.unknown();
    final int expiresIn = json['expiresIn'] is int
        ? json['expiresIn'] as int
        : 600;
    return SendOtpResult(expiresInSeconds: expiresIn);
  }

  @override
  Future<void> verifyOtp(String phoneNumberE164, String code) async {
    final ApiResponse response = await _client.post(
      '/auth/otp/verify',
      body: <String, dynamic>{
        'phoneNumber': phoneNumberE164,
        'code': code,
        'deviceId': await _tokenStorage.deviceId,
      },
    );
    final Map<String, dynamic>? json = response.json;
    if (json == null) throw AppError.unknown();
    await _saveAndNotify(json);
    _scheduleProactiveRefresh();
    unawaited(_initPushAfterAuth());
  }

  @override
  Future<PasswordResetRequestResult> requestPasswordReset(
    String phoneNumberE164,
  ) async {
    final ApiResponse response = await _client.post(
      '/auth/password-reset/request',
      body: <String, dynamic>{'phoneNumber': phoneNumberE164},
    );
    return _parsePasswordResetRequest(response.json);
  }

  @override
  Future<PasswordResetRequestResult> requestPasswordResetByEmail(
    String email,
  ) async {
    final ApiResponse response = await _client.post(
      '/auth/password-reset/request',
      body: <String, dynamic>{'email': email.trim().toLowerCase()},
    );
    return _parsePasswordResetRequest(response.json);
  }

  PasswordResetRequestResult _parsePasswordResetRequest(
    Map<String, dynamic>? json,
  ) {
    if (json == null) throw AppError.unknown();
    final String message =
        json['message']?.toString() ??
        'If an account exists, instructions were sent.';
    final String? channel = json['channel']?.toString();
    final int? expiresIn = json['expiresIn'] is int
        ? json['expiresIn'] as int
        : null;
    return PasswordResetRequestResult(
      message: message,
      channel: channel,
      expiresInSeconds: expiresIn,
    );
  }

  @override
  Future<void> verifyPasswordResetCode(
    String phoneNumberE164,
    String code,
  ) async {
    await _client.post(
      '/auth/password-reset/verify-code',
      body: <String, dynamic>{'phoneNumber': phoneNumberE164, 'code': code},
    );
  }

  @override
  Future<void> confirmPasswordReset({
    required String phoneNumberE164,
    required String code,
    required String newPassword,
  }) async {
    await _client.post(
      '/auth/password-reset/confirm',
      body: <String, dynamic>{
        'phoneNumber': phoneNumberE164,
        'code': code,
        'newPassword': newPassword,
      },
    );
  }

  @override
  Future<void> confirmPasswordResetByEmail({
    required String token,
    required String newPassword,
  }) async {
    await _client.post(
      '/auth/password-reset/email/confirm',
      body: <String, dynamic>{'token': token, 'newPassword': newPassword},
    );
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _client.patch(
      '/auth/me/password',
      body: <String, dynamic>{
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }

  @override
  Future<void> updateHomeLocation({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    await _client.patch(
      '/auth/me/home-location',
      body: <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
        if (label != null && label.trim().isNotEmpty) 'label': label.trim(),
      },
    );
    await UserHomeLocationStore(
      _preferences,
    ).save(latitude: latitude, longitude: longitude, label: label);
  }

  @override
  Future<EmailChangeRequestResult> requestEmailChange(String newEmail) async {
    final ApiResponse response = await _client.patch(
      '/auth/me/email',
      body: <String, dynamic>{'newEmail': newEmail.trim().toLowerCase()},
    );
    final Map<String, dynamic>? json = response.json;
    if (json == null) throw AppError.unknown();
    return EmailChangeRequestResult(
      expiresInSeconds: json['expiresIn'] is int
          ? json['expiresIn'] as int
          : 600,
      devCode: json['devCode']?.toString(),
    );
  }

  @override
  Future<void> confirmEmailChange({
    required String newEmail,
    required String code,
  }) async {
    await _client.post(
      '/auth/me/email/confirm',
      body: <String, dynamic>{
        'newEmail': newEmail.trim().toLowerCase(),
        'code': code.trim(),
      },
    );
  }

  @override
  Future<void> deleteAccount() async {
    final String? userId = _authState.userId;
    try {
      await _client.delete('/auth/me');
      if (userId != null && userId.isNotEmpty) {
        await EulaAcceptanceStore(_preferences).clearForUser(userId);
      }
      await _performLocalLogout();
    } on AppError catch (e) {
      if (e.code == 'UNAUTHORIZED' ||
          e.code == 'INVALID_TOKEN_USER' ||
          e.code == 'SESSION_REVOKED' ||
          e.code == 'ACCOUNT_NOT_ACTIVE' ||
          e.code == 'FORBIDDEN') {
        await _performLocalLogout();
      }
      rethrow;
    }
  }

  bool _clearingLocalSession = false;

  bool _isRestoreStale(int generation) => generation != _restoreGeneration;

  Future<void> _clearLocalSessionCore() async {
    _requiresTermsAcceptance = null;
    if (_clearingLocalSession) return;
    _clearingLocalSession = true;
    _cancelProactiveRefresh();
    // Best-effort: unregister the FCM token server-side before we lose auth.
    // The Postmark/FCM unregister round-trip can race with [setUnauthenticated]
    // below; signOut() handles it on the explicit path, so only fire-and-forget
    // it here (no await) to avoid blocking logout.
    final PushNotificationService? push = pushService;
    if (push != null) {
      unawaited(push.unregisterCurrentToken().catchError((_) {}));
    }
    push?.clearLocalToken();
    _authState.setUnauthenticated();
    _avatarSync.clearAll();
    await _tokenStorage.clearTokens();
    await ChatOutboxStore.shared.clearAll();
    await const EventsLocalCache().clear();
    // Clear per-user outboxes and background hints so the next user does not
    // inherit the previous user's queued state. All best-effort — failures
    // here must not block logout / unauthorized recovery.
    try {
      await EngagementOutboxStore.instance.clearAll();
    } on Object {
      /* best effort */
    }
    try {
      await FieldModeQueue.instance.clearAll();
    } on Object {
      /* best effort */
    }
    try {
      await PushBackgroundPendingStore.clearAll();
    } on Object {
      /* best effort */
    }
    try {
      await UserHomeLocationStore(_preferences).clear();
    } on Object {
      /* best effort */
    }
    try {
      await MapSearchRecentsStore.clear(_preferences);
    } on Object {
      /* best effort */
    }
    try {
      await const CheckInLocalCache().clear();
    } on Object {
      /* best effort */
    }
    try {
      await const EventFeedbackLocalCache().clear();
    } on Object {
      /* best effort */
    }
    try {
      await PendingChatReplyStore.clear();
    } on Object {
      /* best effort */
    }
    try {
      await DiscoveryAnalytics.clearUserConsent();
    } on Object {
      /* best effort */
    }
    await push?.teardownFirebaseListeners();
    ColdStartCoordinator.instance.resetSession();
    _clearingLocalSession = false;
  }

  Future<void> _performLocalLogout() async {
    await _clearLocalSessionCore();
  }

  @override
  Future<void> invalidateLocalSession() => _clearLocalSessionCore();

  @override
  Future<void> signOut() async {
    AppBootstrap.instance.onExplicitSignOut?.call();
    await (pushService?.unregisterCurrentToken() ?? Future<void>.value());
    final String? storedRefresh = await _tokenStorage.refreshToken;
    if (storedRefresh != null && storedRefresh.isNotEmpty) {
      try {
        await _client.post(
          '/auth/logout',
          body: <String, dynamic>{
            'refreshToken': storedRefresh,
            'deviceId': await _tokenStorage.deviceId,
          },
        );
      } on AppError catch (_) {
        // Best-effort server-side revocation; local cleanup happens regardless.
      }
    }
    await _performLocalLogout();
  }

  void _cancelProactiveRefresh() {
    _proactiveRefreshTimer?.cancel();
    _proactiveRefreshTimer = null;
  }

  void _scheduleProactiveRefresh() {
    _cancelProactiveRefresh();
    final String? token = _authState.accessToken;
    if (token == null || token.isEmpty) return;
    final int? exp = getAccessTokenExpiry(token);
    if (exp == null) return;
    final double nowSec = DateTime.now().millisecondsSinceEpoch / 1000.0;
    final double jitter = 0.9 + (math.Random().nextDouble() * 0.2);
    final double delaySec = 0.8 * (exp - nowSec) * jitter;
    // Clock skew: device clock can be ahead of server, making the token look
    // already-expired even though it isn't. Schedule an immediate (short)
    // refresh so we recover instead of waiting indefinitely.
    final Duration delay = delaySec <= 0
        ? const Duration(seconds: 5)
        : Duration(seconds: delaySec.round().clamp(1, 86400));
    _proactiveRefreshTimer = Timer(delay, () async {
      _cancelProactiveRefresh();
      try {
        await _client.refreshSessionQueued();
        _scheduleProactiveRefresh();
      } on Object catch (e, st) {
        AppLog.warn('proactive token refresh failed', error: e, stackTrace: st);
      }
    });
  }

  @override
  Future<void> restoreSession() async {
    final AppBootstrap bootstrap = AppBootstrap.instance;
    bootstrap.suppressUnauthorizedCallback = true;
    try {
      await _restoreSessionBody();
    } finally {
      bootstrap.suppressUnauthorizedCallback = false;
    }
  }

  Future<void> _restoreSessionBody() async {
    _restoreProfileValidationPending = false;
    final int generation = _restoreGeneration;
    final String? storedAccess = await _tokenStorage.accessToken;
    if (_isRestoreStale(generation)) return;
    if (storedAccess == null || storedAccess.isEmpty) {
      _authState.setUnauthenticated();
      _avatarSync.clearAll();
      return;
    }

    String? storedUserId = await _tokenStorage.userId;
    String? storedDisplayName = await _tokenStorage.displayName;
    String? storedPhoneNumber = await _tokenStorage.phoneNumber;
    if (storedUserId == null || storedDisplayName == null) {
      final String? prefsUserId = _preferences.getString(_keyUserId);
      final String? prefsDisplayName = _preferences.getString(_keyDisplayName);
      if (prefsUserId != null || prefsDisplayName != null) {
        storedUserId = prefsUserId ?? '';
        storedDisplayName = prefsDisplayName ?? 'User';
        await _tokenStorage.saveSessionData(
          userId: storedUserId,
          displayName: storedDisplayName,
        );
        await _preferences.remove(_keyUserId);
        await _preferences.remove(_keyDisplayName);
      }
    }

    final String? storedCertIso = await _tokenStorage.organizerCertifiedAtIso;
    final bool hasStoredCertIso =
        storedCertIso != null && storedCertIso.trim().isNotEmpty;
    final DateTime? organizerFromStorage = hasStoredCertIso
        ? DateTime.tryParse(storedCertIso.trim())
        : null;

    if (_isRestoreStale(generation)) return;
    final String? accessBeforeProfile = await _tokenStorage.accessToken;
    if (accessBeforeProfile != storedAccess) return;

    _restoreProfileValidationPending = true;
    _authState.setAuthenticated(
      userId: storedUserId ?? '',
      displayName: storedDisplayName ?? 'User',
      accessToken: storedAccess,
      phoneNumber: storedPhoneNumber,
      organizerCertifiedAt: organizerFromStorage,
      syncOrganizerCertifiedAt: hasStoredCertIso,
    );

    try {
      final ApiResponse response = await _client.get('/auth/me');
      final Map<String, dynamic>? json = response.json;
      if (json == null) {
        await _clearLocalSession(coldRestoreRejection: true);
        return;
      }
      await _applyUserProfile(json, storedAccess);
      unawaited(_initPushAfterAuth());
    } on AppError catch (e) {
      if (e.code == 'UNAUTHORIZED' ||
          e.code == 'INVALID_TOKEN_USER' ||
          e.code == 'SESSION_REVOKED') {
        if (_isRestoreStale(generation)) return;
        final String? accessNow = await _tokenStorage.accessToken;
        if (accessNow != null &&
            accessNow.isNotEmpty &&
            accessNow != storedAccess) {
          return;
        }
        final RefreshOutcome outcome = await _client.refreshSessionQueued();
        if (outcome == RefreshOutcome.success) {
          _scheduleProactiveRefresh();
        } else if (outcome == RefreshOutcome.serverRejected) {
          if (_isRestoreStale(generation)) return;
          final String? accessAfterRefresh = await _tokenStorage.accessToken;
          if (accessAfterRefresh != null &&
              accessAfterRefresh.isNotEmpty &&
              accessAfterRefresh != storedAccess) {
            return;
          }
          await _clearLocalSession(coldRestoreRejection: true);
        }
      } else {
        // Non-auth error (network, server). Keep the cached session and
        // let the user try again later.
      }
    } finally {
      _restoreProfileValidationPending = false;
    }
  }

  @override
  Future<bool> refreshTermsConsentFromServer() async {
    final ApiResponse response = await _client.get('/auth/me');
    final Map<String, dynamic>? profile = response.json;
    if (profile == null) {
      throw AppError.unknown();
    }
    final String? userId = profile['id'] as String?;
    _applyTermsConsentFromJson(profile, userId: userId);
    return _requiresTermsAcceptance ?? true;
  }

  @override
  Future<void> acceptTermsOnServer() async {
    final ApiResponse response = await _client.post(
      '/auth/me/accept-terms',
      body: <String, dynamic>{
        'termsVersion': EulaAcceptanceStore.currentVersion,
      },
    );
    final Map<String, dynamic>? json = response.json;
    if (json == null) {
      throw AppError.unknown();
    }
    _applyTermsConsentFromJson(json, userId: _authState.userId);
  }

  void _applyTermsConsentFromJson(Map<String, dynamic> json, {String? userId}) {
    if (!json.containsKey('requiresTermsAcceptance')) return;
    final bool requires = json['requiresTermsAcceptance'] == true;
    _requiresTermsAcceptance = requires;
    final String uid = userId ?? _authState.userId ?? '';
    if (uid.isNotEmpty) {
      unawaited(
        EulaAcceptanceStore(
          _preferences,
        ).syncFromServer(userId: uid, requiresTermsAcceptance: requires),
      );
    }
  }

  Future<void> _saveAndNotify(Map<String, dynamic> json) async {
    _restoreGeneration++;
    final String? newAccessToken = json['accessToken'] as String?;
    final String? newRefreshToken = json['refreshToken'] as String?;
    final Map<String, dynamic>? user = json['user'] as Map<String, dynamic>?;
    if (newAccessToken == null || newRefreshToken == null || user == null) {
      throw AppError.unknown();
    }

    await _tokenStorage.saveTokens(
      accessToken: newAccessToken,
      refreshToken: newRefreshToken,
    );

    final String id = user['id'] as String? ?? '';
    final String firstName = user['firstName'] as String? ?? '';
    final String lastName = user['lastName'] as String? ?? '';
    final String displayName = '$firstName $lastName'.trim();
    final String? phoneNumber = user['phoneNumber'] as String?;
    final String? priorUserId = _authState.userId;
    final bool switchedAccount =
        priorUserId != null && priorUserId.isNotEmpty && priorUserId != id;
    final bool hasOrganizerCertifiedAtKey = user.containsKey(
      'organizerCertifiedAt',
    );
    final DateTime? organizerCertifiedAt = hasOrganizerCertifiedAtKey
        ? _parseOrganizerCertifiedAtField(user['organizerCertifiedAt'])
        : null;

    _authState.setAuthenticated(
      userId: id,
      displayName: displayName.isEmpty ? id : displayName,
      accessToken: newAccessToken,
      phoneNumber: phoneNumber,
      organizerCertifiedAt: organizerCertifiedAt,
      syncOrganizerCertifiedAt: hasOrganizerCertifiedAtKey || switchedAccount,
    );

    _avatarSync.setRemoteUrl(_extractAvatarUrl(user));

    await _tokenStorage.saveSessionData(
      userId: id,
      displayName: displayName.isEmpty ? id : displayName,
      phoneNumber: phoneNumber,
    );
    if (hasOrganizerCertifiedAtKey || switchedAccount) {
      await _tokenStorage.writeOrganizerCertifiedAt(organizerCertifiedAt);
    }
    _applyTermsConsentFromJson(user, userId: id);
    _client.resetSessionAuthFailureGuard();
    AppBootstrap.instance.armSuppressSessionExpiredWindow(
      const Duration(seconds: 3),
    );
    AppBootstrap.instance.startNotificationsRealtimeIfAuthenticated();
  }

  Future<void> _applyUserProfile(
    Map<String, dynamic> json,
    String accessToken,
  ) async {
    final String id = json['id'] as String? ?? '';
    final String firstName = json['firstName'] as String? ?? '';
    final String lastName = json['lastName'] as String? ?? '';
    final String displayName = '$firstName $lastName'.trim();
    final String? phoneNumber = json['phoneNumber'] as String?;
    // Only sync organizer certification when the server includes the field.
    // Otherwise preserve local state (secure storage + [AuthState]) so a partial
    // `/auth/me` payload cannot clear an existing certification.
    final bool hasOrganizerCertifiedAtKey = json.containsKey(
      'organizerCertifiedAt',
    );
    final DateTime? organizerCertifiedAtFromServer = hasOrganizerCertifiedAtKey
        ? _parseOrganizerCertifiedAtField(json['organizerCertifiedAt'])
        : null;

    _authState.setAuthenticated(
      userId: id,
      displayName: displayName.isEmpty ? id : displayName,
      accessToken: accessToken,
      phoneNumber: phoneNumber,
      organizerCertifiedAt: hasOrganizerCertifiedAtKey
          ? organizerCertifiedAtFromServer
          : _authState.organizerCertifiedAt,
      syncOrganizerCertifiedAt: hasOrganizerCertifiedAtKey,
    );
    _avatarSync.setRemoteUrl(_extractAvatarUrl(json));
    await _tokenStorage.saveSessionData(
      userId: id,
      displayName: displayName.isEmpty ? id : displayName,
      phoneNumber: phoneNumber,
    );
    if (hasOrganizerCertifiedAtKey) {
      await _tokenStorage.writeOrganizerCertifiedAt(
        organizerCertifiedAtFromServer,
      );
    }
    await UserHomeLocationStore(_preferences).applyFromProfileJson(json);
    _applyTermsConsentFromJson(json, userId: id);
    _scheduleProactiveRefresh();
    AppBootstrap.instance.startNotificationsRealtimeIfAuthenticated();
  }

  Future<void> _initPushAfterAuth() async {
    final PushNotificationService? push = pushService;
    if (push == null) return;
    try {
      await push.initialize();
      await push.requestNotificationPermissionIfNeeded();
      await push.ensureNotificationDeliveryReady();
    } on Object catch (e, st) {
      AppLog.warn(
        '[Push] Post-auth init failed',
        error: e,
        stackTrace: st,
        category: 'push',
      );
    }
  }

  String? _extractAvatarUrl(Map<String, dynamic> json) {
    final String? raw = json['avatarUrl'] as String?;
    final String? trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  Future<void> _clearLocalSession({bool coldRestoreRejection = false}) async {
    if (coldRestoreRejection) {
      AppBootstrap.instance.armSuppressSessionExpiredWindow();
    }
    await _clearLocalSessionCore();
  }
}
