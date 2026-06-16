import 'dart:async';
import 'dart:math' as math;

import 'package:chisto_infrastructure/core/auth/auth_state.dart';
import 'package:chisto_infrastructure/core/auth/session_recovery.dart';
import 'package:chisto_infrastructure/core/auth/session_teardown_reason.dart';
import 'package:chisto_infrastructure/core/auth/session_refresh_coordinator.dart';
import 'package:chisto_infrastructure/core/auth/session_cleanup_coordinator.dart';
import 'package:chisto_infrastructure/core/bootstrap/app_bootstrap.dart';
import 'package:chisto_infrastructure/core/bootstrap/cold_start_coordinator.dart';
import 'package:chisto_infrastructure/core/deep_links/deep_link_router.dart';
import 'package:chisto_infrastructure/core/diagnostics/fire_and_log.dart';
import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/logging/app_log.dart';
import 'package:chisto_infrastructure/core/network/api_client.dart';
import 'package:chisto_infrastructure/core/profile/profile_avatar_sync.dart';
import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:chisto_infrastructure/core/providers/root_container.dart';
import 'package:chisto_infrastructure/core/serialization/safe_json.dart';
import 'package:chisto_infrastructure/core/storage/secure_token_storage.dart';
import 'package:chisto_infrastructure/core/time/server_clock.dart';
import 'package:feature_auth/src/data/access_token_expiry.dart';
import 'package:feature_auth/src/data/auth_refresh_retry_policy.dart';
import 'package:feature_auth/src/data/eula_acceptance_store.dart';
import 'package:feature_auth/src/data/user_home_location_store.dart';
import 'package:feature_auth/src/domain/models/auth_session_dtos.dart';
import 'package:feature_auth/src/domain/ports/auth_push_port.dart';
import 'package:feature_auth/src/domain/repositories/auth_repository.dart';
import 'package:flutter/foundation.dart';
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
    SessionCleanupCoordinator? sessionCleanup,
  }) : _client = client,
       _authState = authState,
       _tokenStorage = tokenStorage,
       _preferences = preferences,
       _avatarSync = avatarSync ?? const NoOpProfileAvatarSync(),
       _sessionCleanup =
           sessionCleanup ??
           SessionCleanupCoordinator(
             preferences: preferences,
             avatarSync: avatarSync ?? const NoOpProfileAvatarSync(),
           );

  final ApiClient _client;
  final AuthState _authState;
  final SecureTokenStorage _tokenStorage;
  final SharedPreferences _preferences;
  final ProfileAvatarSync _avatarSync;
  final SessionCleanupCoordinator _sessionCleanup;
  final AuthPushPort? pushService;
  Timer? _proactiveRefreshTimer;

  /// Bumped when sign-in / refresh / OTP verify writes new tokens so an in-flight
  /// [restoreSession] cannot clear the session afterward.
  int _restoreGeneration = 0;

  /// Serializes [_saveAndNotify] and [_clearLocalSessionCore] so login and teardown
  /// cannot interleave token writes/clears.
  Future<void> _sessionMutationChain = Future<void>.value();

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
    await _tokenStorage.setPersistenceMode(persistent: rememberMe);
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
    readRoot(
      appBootstrapProvider,
    ).armSuppressSessionExpiredWindow(const Duration(seconds: 2));
    final int generationAtStart = _restoreGeneration;
    bool isStale() => _isRestoreStale(generationAtStart);
    final String? refreshAtStart = await _tokenStorage.refreshToken;

    for (
      int attempt = 0;
      attempt < kAuthRefreshInvalidTokenMaxAttempts;
      attempt++
    ) {
      final _RefreshAttemptResult result = await _refreshSessionOnce(
        isStale: isStale,
      );
      if (result.outcome == RefreshOutcome.success) {
        SessionRefreshCoordinator.markForegroundRefresh();
        return RefreshOutcome.success;
      }
      if (result.outcome == RefreshOutcome.serverRejected) {
        return RefreshOutcome.serverRejected;
      }
      if (result.invalidRefreshToken &&
          attempt + 1 < kAuthRefreshInvalidTokenMaxAttempts) {
        await authRefreshInvalidTokenBackoff();
        continue;
      }
      if (result.invalidRefreshToken) {
        break;
      }
      return RefreshOutcome.transient;
    }

    final String? latestRefresh = await _tokenStorage.refreshToken;
    if (latestRefresh != null &&
        latestRefresh.isNotEmpty &&
        latestRefresh != refreshAtStart) {
      final _RefreshAttemptResult recovery = await _refreshSessionOnce(
        isStale: isStale,
      );
      if (recovery.outcome == RefreshOutcome.success) {
        SessionRefreshCoordinator.markForegroundRefresh();
        return RefreshOutcome.success;
      }
      if (recovery.outcome == RefreshOutcome.serverRejected) {
        return RefreshOutcome.serverRejected;
      }
      if (!recovery.invalidRefreshToken) {
        return RefreshOutcome.transient;
      }
    }

    return RefreshOutcome.serverRejected;
  }

  Future<_RefreshAttemptResult> _refreshSessionOnce({
    required bool Function() isStale,
  }) async {
    try {
      final String? storedRefresh = await _tokenStorage.refreshToken;
      if (storedRefresh == null || storedRefresh.isEmpty) {
        return _RefreshAttemptResult(
          isStale() ? RefreshOutcome.success : RefreshOutcome.serverRejected,
        );
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
        return const _RefreshAttemptResult(RefreshOutcome.transient);
      }
      if (isStale()) {
        return const _RefreshAttemptResult(RefreshOutcome.success);
      }
      await _saveAndNotify(json);
      _scheduleProactiveRefresh();
      return const _RefreshAttemptResult(RefreshOutcome.success);
    } on AppError catch (e) {
      if (isAuthRefreshRotationRaceError(e.code)) {
        return const _RefreshAttemptResult(
          RefreshOutcome.transient,
          invalidRefreshToken: true,
        );
      }
      if (isAuthRefreshServerRejectedError(e.code)) {
        return _RefreshAttemptResult(
          isStale() ? RefreshOutcome.success : RefreshOutcome.serverRejected,
        );
      }
      return const _RefreshAttemptResult(RefreshOutcome.transient);
    } on Object {
      return const _RefreshAttemptResult(RefreshOutcome.transient);
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
  Future<void> verifyOtp(
    String phoneNumberE164,
    String code, {
    bool rememberMe = true,
  }) async {
    await _tokenStorage.setPersistenceMode(persistent: rememberMe);
    final ApiResponse response = await _client.post(
      '/auth/otp/verify',
      body: <String, dynamic>{
        'phoneNumber': phoneNumberE164,
        'code': code,
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
    final String? devCode = json['devCode']?.toString();
    return PasswordResetRequestResult(message: message, devCode: devCode);
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
  Future<void> verifyPasswordResetCodeByEmail(String email, String code) async {
    await _client.post(
      '/auth/password-reset/email/verify-code',
      body: <String, dynamic>{
        'email': email.trim().toLowerCase(),
        'code': code,
      },
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
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _client.post(
      '/auth/password-reset/email/confirm',
      body: <String, dynamic>{
        'email': email.trim().toLowerCase(),
        'code': code,
        'newPassword': newPassword,
      },
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
    final ApiResponse response = await _client.patch(
      '/auth/me/home-location',
      body: <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
        if (label != null && label.trim().isNotEmpty) 'label': label.trim(),
      },
    );
    final Map<String, dynamic>? json = response.json;
    if (json != null) {
      await UserHomeLocationStore(
        _preferences,
        userId: _authState.userId,
      ).applyFromProfileJson(json);
      return;
    }
    await UserHomeLocationStore(_preferences, userId: _authState.userId).save(
      latitude: latitude,
      longitude: longitude,
      label: label,
      homeLocationSetAt: DateTime.now().toUtc().toIso8601String(),
    );
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
      devCode: kDebugMode ? json['devCode']?.toString() : null,
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

  Future<T> _withSessionMutationLock<T>(Future<T> Function() action) async {
    final Future<void> prior = _sessionMutationChain;
    final Completer<void> gate = Completer<void>();
    _sessionMutationChain = gate.future;
    await prior;
    try {
      return await action();
    } finally {
      gate.complete();
    }
  }

  Future<void> _clearLocalSessionCore({
    int? observedEpoch,
    SessionTeardownReason? reason,
  }) async {
    await _withSessionMutationLock(() async {
      if (observedEpoch != null && observedEpoch != _authState.sessionEpoch) {
        return;
      }
      _requiresTermsAcceptance = null;
      if (_clearingLocalSession) return;
      _clearingLocalSession = true;
      if (reason != null) {
        AppLog.warn(
          'session teardown',
          error: reason.logLabel,
          category: 'auth',
        );
      }
      _cancelProactiveRefresh();
      // Best-effort: unregister the FCM token server-side before we lose auth.
      // The Postmark/FCM unregister round-trip can race with [setUnauthenticated]
      // below; signOut() handles it on the explicit path, so only fire-and-forget
      // it here (no await) to avoid blocking logout.
      final AuthPushPort? push = pushService;
      if (push != null) {
        fireAndLog(
          push.unregisterCurrentToken(),
          op: 'signOut unregister push token',
          category: 'auth',
        );
      }
      push?.clearLocalToken();
      _authState.setUnauthenticated();
      await _tokenStorage.clearTokens();
      await _sessionCleanup.clearLocalPii(pushService: push);
      DeepLinkRouter.clearPendingAuthenticatedUri();
      ColdStartCoordinator.instance.resetSession();
      ServerClock.instance.reset();
      _clearingLocalSession = false;
    });
  }

  Future<void> _performLocalLogout() async {
    await _clearLocalSessionCore(reason: SessionTeardownReason.explicitSignOut);
  }

  @override
  Future<void> invalidateLocalSession({
    int? observedEpoch,
    SessionTeardownReason? reason,
  }) => _clearLocalSessionCore(observedEpoch: observedEpoch, reason: reason);

  @override
  Future<void> signOut() async {
    readRoot(appBootstrapProvider).onExplicitSignOut?.call();
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
    final double nowSec =
        ServerClock.instance.nowUtc().millisecondsSinceEpoch / 1000.0;
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
        final bool invalidated = await SessionRecovery.refreshBeforeInvalidate(
          reason: SessionTeardownReason.proactiveRefreshRejected,
          delayedRetry: SessionRecovery.resumeDelayedRetry(),
        );
        if (!invalidated && _authState.isAuthenticated) {
          _scheduleProactiveRefresh();
        }
      } on Object catch (e, st) {
        AppLog.warn('proactive token refresh failed', error: e, stackTrace: st);
      }
    });
  }

  @override
  Future<void> restoreSession() async {
    final AppBootstrap bootstrap = readRoot(appBootstrapProvider);
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
    final String? storedPhoneNumber = await _tokenStorage.phoneNumber;
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
        await _clearLocalSession(
          coldRestoreRejection: true,
          reason: SessionTeardownReason.coldRestoreRejected,
        );
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
          await _clearLocalSession(
            coldRestoreRejection: true,
            reason: SessionTeardownReason.coldRestoreRejected,
          );
        }
      } else {
        // Non-auth error (network, server). Keep cached session but do not trust
        // unvalidated local home coords for the location gate.
        await UserHomeLocationStore.clearAllForSession(
          _preferences,
          userId: storedUserId,
        );
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
    await _withSessionMutationLock(() async {
      _restoreGeneration++;
      final String? newAccessToken = json['accessToken'] as String?;
      final String? newRefreshToken = json['refreshToken'] as String?;
      final Map<String, dynamic>? user = safeAsStringKeyedMap(json['user']);
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
      if (switchedAccount) {
        await UserHomeLocationStore.clearAllForSession(
          _preferences,
          userId: priorUserId,
        );
      }
      await _syncProfileFromServer();
      _client.resetSessionAuthFailureGuard();
      readRoot(
        appBootstrapProvider,
      ).armSuppressSessionExpiredWindow(const Duration(seconds: 3));
      readRoot(
        appBootstrapProvider,
      ).startNotificationsRealtimeIfAuthenticated();
    });
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
    await UserHomeLocationStore(
      _preferences,
      userId: id,
    ).applyFromProfileJson(json);
    _applyTermsConsentFromJson(json, userId: id);
    _scheduleProactiveRefresh();
    readRoot(appBootstrapProvider).startNotificationsRealtimeIfAuthenticated();
    readRoot(appBootstrapProvider).startReportsRealtimeIfAuthenticated();
  }

  Future<void> _syncProfileFromServer() async {
    final String? accessToken = await _tokenStorage.accessToken;
    if (accessToken == null || accessToken.isEmpty) return;
    final ApiResponse response = await _client.get('/auth/me');
    final Map<String, dynamic>? json = response.json;
    if (json == null) {
      throw AppError.unknown();
    }
    await _applyUserProfile(json, accessToken);
  }

  Future<void> _initPushAfterAuth() async {
    final AuthPushPort? push = pushService;
    if (push == null) return;
    try {
      await push.initialize();
      await push.requestNotificationPermissionIfNeeded();
      await readRoot(appBootstrapProvider).syncUserLocaleToServer();
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

  Future<void> _clearLocalSession({
    bool coldRestoreRejection = false,
    SessionTeardownReason? reason,
  }) async {
    if (coldRestoreRejection) {
      readRoot(appBootstrapProvider).armSuppressSessionExpiredWindow();
    }
    await _clearLocalSessionCore(reason: reason);
  }
}

class _RefreshAttemptResult {
  const _RefreshAttemptResult(this.outcome, {this.invalidRefreshToken = false});

  final RefreshOutcome outcome;
  final bool invalidRefreshToken;
}
