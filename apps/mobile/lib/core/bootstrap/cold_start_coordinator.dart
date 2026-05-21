import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/bootstrap/app_bootstrap.dart';
import 'package:chisto_mobile/core/deep_links/deep_link_router.dart';
import 'package:chisto_mobile/core/deep_links/share_token_from_route.dart';
import 'package:chisto_mobile/core/logging/app_log.dart';
import 'package:chisto_mobile/features/notifications/data/notification_open_router.dart';

/// Cold-start routing: one deterministic launch action after bootstrap + session.
enum LaunchIntentKind {
  pushTap,
  deepLink,
}

class LaunchIntent {
  const LaunchIntent.push(this.message) : kind = LaunchIntentKind.pushTap, uri = null;

  const LaunchIntent.deepLink(this.uri) : kind = LaunchIntentKind.deepLink, message = null;

  final LaunchIntentKind kind;
  final RemoteMessage? message;
  final Uri? uri;
}

/// Serializes push-tap and deep-link handling so they never race session restore.
class ColdStartCoordinator {
  ColdStartCoordinator._();

  static final ColdStartCoordinator instance = ColdStartCoordinator._();

  bool _bootstrapReady = false;
  bool _sessionReady = false;
  RemoteMessage? _queuedPush;
  Uri? _queuedDeepLink;
  bool _applied = false;

  bool get isReadyForLaunch => _bootstrapReady && _sessionReady;

  void markBootstrapReady() {
    _bootstrapReady = true;
  }

  void markSessionReady() {
    _sessionReady = true;
  }

  void resetSession() {
    _sessionReady = false;
    _queuedPush = null;
    _queuedDeepLink = null;
    _applied = false;
  }

  /// Queues a cold-start notification tap (priority over deep link).
  void queueColdStartPush(RemoteMessage message) {
    _queuedPush = message;
  }

  /// Queues a deep link until [isReadyForLaunch] or applies immediately via [tryApply].
  void queueDeepLink(Uri uri) {
    if (_applied) {
      return;
    }
    _queuedDeepLink = uri;
  }

  LaunchIntent? peekPendingIntent() {
    if (!isReadyForLaunch || _applied) {
      return null;
    }
    final RemoteMessage? push = _queuedPush;
    if (push != null) {
      return LaunchIntent.push(push);
    }
    final Uri? link = _queuedDeepLink;
    if (link != null) {
      return LaunchIntent.deepLink(link);
    }
    return null;
  }

  /// Applies the highest-priority pending intent once per cold start.
  bool tryApply({
    required NavigatorState navigator,
    required BuildContext context,
  }) {
    if (!isReadyForLaunch || _applied) {
      return false;
    }
    final LaunchIntent? intent = peekPendingIntent();
    if (intent == null) {
      return false;
    }
    _applied = true;
    switch (intent.kind) {
      case LaunchIntentKind.pushTap:
        final RemoteMessage? message = intent.message;
        if (message != null && context.mounted) {
          NotificationOpenRouter.handleOpen(context, message);
        }
        _queuedPush = null;
        return true;
      case LaunchIntentKind.deepLink:
        final Uri? uri = intent.uri;
        if (uri == null) {
          return false;
        }
        final bool handled = DeepLinkRouter.handleUri(
          navigator,
          uri,
          isAuthenticated: AppBootstrap.instance.authState.isAuthenticated,
        );
        if (handled) {
          unawaited(_trackShareOpen(uri));
        } else {
          AppLog.verbose('[ColdStart] Unhandled deep link: $uri');
        }
        _queuedDeepLink = null;
        return handled;
    }
  }

  Future<void> _trackShareOpen(Uri uri) async {
    final DeepLinkRoute? parsed = DeepLinkRouter.parse(uri);
    final String? token = shareTokenFromDeepLinkRoute(parsed);
    if (token == null || token.isEmpty) {
      return;
    }
    try {
      await AppBootstrap.instance.sitesRepository.ingestSiteShareOpen(
        token: token,
        eventType: 'OPEN',
        source: 'APP',
      );
    } on Object catch (e, st) {
      AppLog.warn('[ColdStart] Share open tracking failed', error: e, stackTrace: st);
    }
  }
}
