import 'package:chisto_infrastructure/core/config/app_config.dart';
import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/logging/app_log.dart';
import 'package:chisto_infrastructure/core/network/api_client.dart';
import 'package:chisto_infrastructure/core/storage/secure_token_storage.dart';
import 'package:flutter/foundation.dart';

/// Headless `/auth/refresh` for background isolates (no [AppBootstrap]).
abstract final class BackgroundSessionRefresh {
  static Future<RefreshOutcome> tryRefresh({
    AppConfig? config,
    SecureTokenStorage? tokenStorage,
  }) async {
    final AppConfig resolvedConfig = config ?? AppConfig.fromEnvironment();
    final SecureTokenStorage storage = tokenStorage ?? SecureTokenStorage();
    final String? storedRefresh = await storage.refreshToken;
    if (storedRefresh == null || storedRefresh.isEmpty) {
      return RefreshOutcome.serverRejected;
    }

    String? accessToken = await storage.accessToken;
    final ApiClient client = ApiClient(
      config: resolvedConfig,
      accessToken: () => accessToken,
      onUnauthorized: () {},
    );
    try {
      final response = await client.post(
        '/auth/refresh',
        body: <String, dynamic>{
          'refreshToken': storedRefresh,
          'deviceId': await storage.deviceId,
        },
      );
      final Map<String, dynamic>? json = response.json;
      if (json == null) {
        return RefreshOutcome.transient;
      }
      final String? newAccess = json['accessToken'] as String?;
      final String? newRefresh = json['refreshToken'] as String?;
      if (newAccess == null || newRefresh == null) {
        return RefreshOutcome.transient;
      }
      await storage.saveTokens(
        accessToken: newAccess,
        refreshToken: newRefresh,
      );
      accessToken = newAccess;
      return RefreshOutcome.success;
    } on AppError catch (e) {
      if (e.code == 'UNAUTHORIZED' ||
          e.code == 'INVALID_TOKEN_USER' ||
          e.code == 'SESSION_REVOKED') {
        return RefreshOutcome.serverRejected;
      }
      return RefreshOutcome.transient;
    } on Object catch (e, st) {
      if (kDebugMode) {
        AppLog.verbose('[BackgroundSessionRefresh] failed: $e\n$st');
      }
      return RefreshOutcome.transient;
    } finally {
      client.dispose();
    }
  }

  /// Returns a usable access token, attempting refresh when none is stored.
  static Future<String?> resolveAccessToken({
    AppConfig? config,
    SecureTokenStorage? tokenStorage,
    bool attemptRefreshWhenMissing = true,
  }) async {
    final SecureTokenStorage storage = tokenStorage ?? SecureTokenStorage();
    final String? existing = await storage.accessToken;
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    if (!attemptRefreshWhenMissing) {
      return null;
    }
    final RefreshOutcome outcome = await tryRefresh(
      config: config,
      tokenStorage: storage,
    );
    if (outcome != RefreshOutcome.success) {
      if (kDebugMode) {
        AppLog.verbose(
          '[BackgroundSessionRefresh] no access token (refresh=$outcome)',
        );
      }
      return null;
    }
    return storage.accessToken;
  }
}
