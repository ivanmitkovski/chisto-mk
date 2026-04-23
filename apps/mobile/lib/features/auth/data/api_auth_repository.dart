import 'dart:async';

import 'package:chisto_mobile/core/auth/auth_state.dart';
import 'package:chisto_mobile/core/errors/app_error.dart';
import 'package:chisto_mobile/core/network/api_client.dart';
import 'package:chisto_mobile/core/storage/secure_token_storage.dart';
import 'package:chisto_mobile/features/auth/data/access_token_expiry.dart';
import 'package:chisto_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:chisto_mobile/features/notifications/data/push_notification_service.dart';
import 'package:chisto_mobile/features/events/data/chat/outbox/chat_outbox_store.dart';
import 'package:chisto_mobile/features/events/data/events_local_cache.dart';
import 'package:chisto_mobile/features/profile/data/profile_avatar_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Citizen auth over HTTP — paths align with NestJS `AuthController` in `apps/api`:
/// `POST /auth/register`, `/auth/login`, `/auth/refresh`, `/auth/logout`;
/// `POST /auth/otp/send`, `/auth/otp/verify`,
/// `/auth/password-reset/request`, `/auth/password-reset/verify-code`,
/// `/auth/password-reset/confirm`;
/// `GET`/`PATCH` `/auth/me`, `PATCH /auth/me/password`, `DELETE /auth/me`;
/// multipart `POST`/`DELETE` `/auth/me/avatar`.
const String _keyUserId = 'chisto_user_id';
const String _keyDisplayName = 'chisto_display_name';

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository({
    required ApiClient client,
    required AuthState authState,
    required SecureTokenStorage tokenStorage,
    required SharedPreferences preferences,
    this.pushService,
  })  : _client = client,
        _authState = authState,
        _tokenStorage = tokenStorage,
        _preferences = preferences;

  final ApiClient _client;
  final AuthState _authState;
  final SecureTokenStorage _tokenStorage;
  final SharedPreferences _preferences;
  final PushNotificationService? pushService;
  Timer? _proactiveRefreshTimer;

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
  }) async {
    final ApiResponse response = await _client.post(
      '/auth/login',
      body: <String, dynamic>{
        'phoneNumber': phoneNumber,
        'password': password,
      },
    );
    final Map<String, dynamic>? json = response.json;
    if (json == null) throw AppError.unknown();
    await _saveAndNotify(json);
    _scheduleProactiveRefresh();
    unawaited(_initPushAfterAuth());
  }

  @override
  Future<void> signUp({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    final ApiResponse response = await _client.post(
      '/auth/register',
      body: <String, dynamic>{
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'email': email.trim().toLowerCase(),
        'phoneNumber': phoneNumber,
        'password': password,
      },
    );
    final Map<String, dynamic>? json = response.json;
    if (json == null) throw AppError.unknown();
    await _saveAndNotify(json);
    _scheduleProactiveRefresh();
    unawaited(_initPushAfterAuth());
  }

  @override
  Future<void> refreshSession() async {
    final String? storedRefresh = await _tokenStorage.refreshToken;
    if (storedRefresh == null || storedRefresh.isEmpty) {
      throw AppError.unauthorized();
    }

    final ApiResponse response = await _client.post(
      '/auth/refresh',
      body: <String, dynamic>{'refreshToken': storedRefresh},
    );
    final Map<String, dynamic>? json = response.json;
    if (json == null) throw AppError.unknown();
    await _saveAndNotify(json);
    _scheduleProactiveRefresh();
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
    await _client.post(
      '/auth/otp/verify',
      body: <String, dynamic>{
        'phoneNumber': phoneNumberE164,
        'code': code,
      },
    );
  }

  @override
  Future<SendOtpResult> requestPasswordReset(String phoneNumberE164) async {
    final ApiResponse response = await _client.post(
      '/auth/password-reset/request',
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
  Future<void> verifyPasswordResetCode(String phoneNumberE164, String code) async {
    await _client.post(
      '/auth/password-reset/verify-code',
      body: <String, dynamic>{
        'phoneNumber': phoneNumberE164,
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
  Future<void> deleteAccount() async {
    try {
      await _client.delete('/auth/me');
      await _performLocalLogout();
    } on AppError catch (e) {
      if (e.code == 'UNAUTHORIZED' || e.code == 'INVALID_TOKEN_USER' || e.code == 'FORBIDDEN') {
        await _performLocalLogout();
      }
      rethrow;
    }
  }

  Future<void> _clearLocalSessionCore() async {
    _cancelProactiveRefresh();
    unawaited(pushService?.unregisterCurrentToken() ?? Future<void>.value());
    _authState.setUnauthenticated();
    profileAvatarState.setRemoteUrl(null);
    profileAvatarState.clearLocalPath();
    await _tokenStorage.clearTokens();
    await ChatOutboxStore.shared.clearAll();
    await const EventsLocalCache().clear();
  }

  Future<void> _performLocalLogout() async {
    await _clearLocalSessionCore();
  }

  @override
  Future<void> invalidateLocalSession() => _clearLocalSessionCore();

  @override
  Future<void> signOut() async {
    final String? storedRefresh = await _tokenStorage.refreshToken;
    if (storedRefresh != null && storedRefresh.isNotEmpty) {
      try {
        await _client.post(
          '/auth/logout',
          body: <String, dynamic>{'refreshToken': storedRefresh},
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
        DateTime.now().millisecondsSinceEpoch / 1000.0;
    final double delaySec = 0.8 * (exp - nowSec);
    if (delaySec <= 0) return;
    _proactiveRefreshTimer = Timer(
      Duration(seconds: delaySec.round().clamp(1, 86400)),
      () async {
        _cancelProactiveRefresh();
        try {
          await refreshSession();
          _scheduleProactiveRefresh();
        } catch (_) {}
      },
    );
  }

  @override
  Future<void> restoreSession() async {
    final String? storedAccess = await _tokenStorage.accessToken;
    if (storedAccess == null || storedAccess.isEmpty) {
      _authState.setUnauthenticated();
      profileAvatarState.setRemoteUrl(null);
      profileAvatarState.clearLocalPath();
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
    final DateTime? organizerFromStorage =
        hasStoredCertIso ? DateTime.tryParse(storedCertIso.trim()) : null;

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
        await _clearLocalSession();
        return;
      }
      await _applyUserProfile(json, storedAccess);
      _scheduleProactiveRefresh();
      unawaited(_initPushAfterAuth());
    } on AppError catch (e) {
      if (e.code == 'UNAUTHORIZED' || e.code == 'INVALID_TOKEN_USER') {
        try {
          await refreshSession();
          _scheduleProactiveRefresh();
        } on AppError catch (_) {
          await _clearLocalSession();
        }
      } else {
        // Non-auth error (network, server). Keep the cached session and
        // let the user try again later.
      }
    }
  }

  Future<void> _saveAndNotify(Map<String, dynamic> json) async {
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
    final bool switchedAccount = priorUserId != null &&
        priorUserId.isNotEmpty &&
        priorUserId != id;
    final bool hasOrganizerCertifiedAtKey =
        user.containsKey('organizerCertifiedAt');
    final String? certifiedAtRaw = user['organizerCertifiedAt'] as String?;
    final DateTime? organizerCertifiedAt =
        certifiedAtRaw != null && certifiedAtRaw.trim().isNotEmpty
            ? DateTime.tryParse(certifiedAtRaw.trim())
            : null;

    _authState.setAuthenticated(
      userId: id,
      displayName: displayName.isEmpty ? id : displayName,
      accessToken: newAccessToken,
      phoneNumber: phoneNumber,
      organizerCertifiedAt: organizerCertifiedAt,
      syncOrganizerCertifiedAt: hasOrganizerCertifiedAtKey || switchedAccount,
    );

    profileAvatarState.setRemoteUrl(_extractAvatarUrl(user));

    await _tokenStorage.saveSessionData(
      userId: id,
      displayName: displayName.isEmpty ? id : displayName,
      phoneNumber: phoneNumber,
    );
    if (hasOrganizerCertifiedAtKey || switchedAccount) {
      await _tokenStorage.writeOrganizerCertifiedAt(organizerCertifiedAt);
    }
  }

  Future<void> _applyUserProfile(Map<String, dynamic> json, String accessToken) async {
    final String id = json['id'] as String? ?? '';
    final String firstName = json['firstName'] as String? ?? '';
    final String lastName = json['lastName'] as String? ?? '';
    final String displayName = '$firstName $lastName'.trim();
    final String? phoneNumber = json['phoneNumber'] as String?;
    final String? certifiedAtRaw = json['organizerCertifiedAt'] as String?;
    final DateTime? organizerCertifiedAt =
        certifiedAtRaw != null ? DateTime.tryParse(certifiedAtRaw) : null;

    _authState.setAuthenticated(
      userId: id,
      displayName: displayName.isEmpty ? id : displayName,
      accessToken: accessToken,
      phoneNumber: phoneNumber,
      organizerCertifiedAt: organizerCertifiedAt,
      syncOrganizerCertifiedAt: true,
    );
    profileAvatarState.setRemoteUrl(_extractAvatarUrl(json));
    await _tokenStorage.saveSessionData(
      userId: id,
      displayName: displayName.isEmpty ? id : displayName,
      phoneNumber: phoneNumber,
    );
    await _tokenStorage.writeOrganizerCertifiedAt(organizerCertifiedAt);
    _scheduleProactiveRefresh();
  }

  Future<void> _initPushAfterAuth() async {
    try {
      await pushService?.initialize();
    } catch (_) {}
  }

  String? _extractAvatarUrl(Map<String, dynamic> json) {
    final String? raw = json['avatarUrl'] as String?;
    final String? trimmed = raw?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  Future<void> _clearLocalSession() async {
    await _clearLocalSessionCore();
  }
}
