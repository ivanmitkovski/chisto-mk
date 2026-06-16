import 'package:chisto_infrastructure/core/auth/session_refresh_coordinator.dart';
import 'package:chisto_infrastructure/core/config/app_config.dart';
import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/logging/app_log.dart';
import 'package:chisto_infrastructure/core/network/api_client.dart';
import 'package:chisto_infrastructure/core/storage/secure_token_storage.dart';
import 'package:feature_auth/src/data/auth_refresh_retry_policy.dart';
import 'package:flutter/foundation.dart';

/// Headless `/auth/refresh` for background isolates (no [AppBootstrap]).
abstract final class BackgroundSessionRefresh {
  static Future<RefreshOutcome> tryRefresh({
    AppConfig? config,
    SecureTokenStorage? tokenStorage,
    ApiClient? clientOverride,
  }) async {
    if (SessionRefreshCoordinator.shouldSkipBackgroundRefresh()) {
      return RefreshOutcome.transient;
    }

    final AppConfig resolvedConfig = config ?? AppConfig.fromEnvironment();
    final SecureTokenStorage storage = tokenStorage ?? SecureTokenStorage();
    final String? refreshAtStart = await storage.refreshToken;
    if (refreshAtStart == null || refreshAtStart.isEmpty) {
      return RefreshOutcome.serverRejected;
    }

    String? accessToken = await storage.accessToken;
    final ApiClient client =
        clientOverride ??
        ApiClient(
          config: resolvedConfig,
          accessToken: () => accessToken,
          onUnauthorized: (_) {},
        );
    final bool ownsClient = clientOverride == null;
    try {
      RefreshOutcome? lastOutcome;
      for (
        int attempt = 0;
        attempt < kAuthRefreshInvalidTokenMaxAttempts;
        attempt++
      ) {
        final _BackgroundRefreshAttempt attemptResult = await _refreshOnce(
          client: client,
          storage: storage,
        );
        lastOutcome = attemptResult.outcome;
        if (attemptResult.outcome == RefreshOutcome.success) {
          accessToken = await storage.accessToken;
          return RefreshOutcome.success;
        }
        if (attemptResult.outcome == RefreshOutcome.serverRejected) {
          return RefreshOutcome.serverRejected;
        }
        if (attemptResult.invalidRefreshToken &&
            attempt + 1 < kAuthRefreshInvalidTokenMaxAttempts) {
          await authRefreshInvalidTokenBackoff();
          continue;
        }
        if (attemptResult.invalidRefreshToken) {
          break;
        }
        return RefreshOutcome.transient;
      }

      final String? latestRefresh = await storage.refreshToken;
      if (latestRefresh != null &&
          latestRefresh.isNotEmpty &&
          latestRefresh != refreshAtStart) {
        final _BackgroundRefreshAttempt recovery = await _refreshOnce(
          client: client,
          storage: storage,
        );
        if (recovery.outcome == RefreshOutcome.success) {
          return RefreshOutcome.success;
        }
        if (recovery.outcome == RefreshOutcome.serverRejected) {
          return RefreshOutcome.serverRejected;
        }
        if (!recovery.invalidRefreshToken) {
          return RefreshOutcome.transient;
        }
      }

      return lastOutcome == RefreshOutcome.serverRejected
          ? RefreshOutcome.serverRejected
          : RefreshOutcome.transient;
    } on Object catch (e, st) {
      if (kDebugMode) {
        AppLog.verbose('[BackgroundSessionRefresh] failed: $e\n$st');
      }
      return RefreshOutcome.transient;
    } finally {
      if (ownsClient) {
        client.dispose();
      }
    }
  }

  static Future<_BackgroundRefreshAttempt> _refreshOnce({
    required ApiClient client,
    required SecureTokenStorage storage,
  }) async {
    final String? storedRefresh = await storage.refreshToken;
    if (storedRefresh == null || storedRefresh.isEmpty) {
      return const _BackgroundRefreshAttempt(RefreshOutcome.serverRejected);
    }

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
        return const _BackgroundRefreshAttempt(RefreshOutcome.transient);
      }
      final String? newAccess = json['accessToken'] as String?;
      final String? newRefresh = json['refreshToken'] as String?;
      if (newAccess == null || newRefresh == null) {
        return const _BackgroundRefreshAttempt(RefreshOutcome.transient);
      }
      await storage.saveTokens(
        accessToken: newAccess,
        refreshToken: newRefresh,
      );
      return const _BackgroundRefreshAttempt(RefreshOutcome.success);
    } on AppError catch (e) {
      if (isAuthRefreshRotationRaceError(e.code)) {
        return const _BackgroundRefreshAttempt(
          RefreshOutcome.transient,
          invalidRefreshToken: true,
        );
      }
      if (isAuthRefreshServerRejectedError(e.code)) {
        return const _BackgroundRefreshAttempt(RefreshOutcome.serverRejected);
      }
      return const _BackgroundRefreshAttempt(RefreshOutcome.transient);
    } on Object {
      return const _BackgroundRefreshAttempt(RefreshOutcome.transient);
    }
  }

  /// Returns a usable access token, attempting refresh when none is stored.
  static Future<String?> resolveAccessToken({
    AppConfig? config,
    SecureTokenStorage? tokenStorage,
    bool attemptRefreshWhenMissing = true,
  }) async {
    if (SessionRefreshCoordinator.shouldSkipBackgroundRefresh()) {
      final SecureTokenStorage storage = tokenStorage ?? SecureTokenStorage();
      final String? existing = await storage.accessToken;
      if (existing != null && existing.isNotEmpty) {
        return existing;
      }
    }

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

class _BackgroundRefreshAttempt {
  const _BackgroundRefreshAttempt(
    this.outcome, {
    this.invalidRefreshToken = false,
  });

  final RefreshOutcome outcome;
  final bool invalidRefreshToken;
}
