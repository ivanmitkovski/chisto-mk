import 'dart:async';

import 'package:chisto_infrastructure/core/errors/app_error.dart';
import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:chisto_infrastructure/core/logging/app_log.dart';
import 'package:chisto_infrastructure/core/providers/refresh_signals_providers.dart';
import 'package:chisto_infrastructure/shared/widgets/atoms/app_snack.dart';
import 'package:feature_notifications/src/data/push_notification_service.dart';
import 'package:feature_notifications/src/presentation/push_permission_ui.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Push bootstrap and permission prompts extracted from [main.dart].
class PushSetupCoordinator {
  PushSetupCoordinator({
    required PushNotificationService pushService,
    required SharedPreferences preferences,
    required GlobalKey<NavigatorState> navigatorKey,
    required bool Function() isMounted,
    required void Function(RemoteMessage message) onForegroundMessage,
  }) : _push = pushService,
       _prefs = preferences,
       _navigatorKey = navigatorKey,
       _isMounted = isMounted,
       _onForegroundMessage = onForegroundMessage;

  final PushNotificationService _push;
  final SharedPreferences _prefs;
  final GlobalKey<NavigatorState> _navigatorKey;
  final bool Function() _isMounted;
  final void Function(RemoteMessage message) _onForegroundMessage;

  StreamSubscription<RemoteMessage>? _foregroundPushSubscription;

  Future<void> bootstrap() async {
    _push.onRegistrationFailure = (AppError error) {
      if (!_isMounted()) {
        return;
      }
      final BuildContext? ctx = _navigatorKey.currentContext;
      if (ctx == null || !ctx.mounted) {
        return;
      }
      AppSnack.show(
        ctx,
        message: ctx.l10n.pushRegistrationFailedSnack,
        type: AppSnackType.warning,
      );
    };
    await _push.initialize(appLanguageOverride: readAppLocaleOverride());
    await _push.consumePendingLaunchNotification();
    if (!_isMounted()) {
      return;
    }
    _foregroundPushSubscription = _push.foregroundMessages.listen(
      _onForegroundMessage,
    );
  }

  /// Retries because the navigator may not be ready at first frame (iOS needs the
  /// system sheet once so Settings → Notifications appears for Chisto.mk).
  Future<void> offerPermissionWithRetries() async {
    const List<int> delaysMs = <int>[400, 2500, 8000];
    for (final int delayMs in delaysMs) {
      await Future<void>.delayed(Duration(milliseconds: delayMs));
      if (!_isMounted()) {
        return;
      }
      final bool done = await _tryOfferPushPermissionOnce();
      if (done) {
        return;
      }
    }
  }

  Future<bool> _tryOfferPushPermissionOnce() async {
    if (!_push.isFirebaseReady) {
      return false;
    }

    if (await _push.hasUsableAlertPermission()) {
      await _push.ensureNotificationDeliveryReady();
      return true;
    }

    if (!await _push.shouldPromptForNotificationPermission()) {
      if (await _push.isNotificationPermissionPermanentlyDenied()) {
        await _promptPushOpenSettingsIfNeeded();
      }
      return true;
    }

    final int? deniedAtMs = _prefs.getInt(kPushPermissionDeniedAtKey);
    if (deniedAtMs != null) {
      final Duration sinceDenied = DateTime.now().difference(
        DateTime.fromMillisecondsSinceEpoch(deniedAtMs),
      );
      if (sinceDenied < const Duration(days: 7)) {
        return false;
      }
    }

    await _offerPushPermissionIfNeeded();
    return _push.hasUsableAlertPermission();
  }

  Future<void> _offerPushPermissionIfNeeded() async {
    if (!_isMounted()) {
      return;
    }
    if (!_push.isFirebaseReady) {
      return;
    }

    bool rationaleSeen =
        _prefs.getBool(kPushPermissionRationaleSeenKey) ?? false;
    if (!rationaleSeen &&
        (_prefs.getBool(kPushOsPermissionFlowCompletedKey) ?? false)) {
      rationaleSeen = true;
      await _prefs.setBool(kPushPermissionRationaleSeenKey, true);
    }

    if (!rationaleSeen) {
      final BuildContext? ctx = _navigatorKey.currentContext;
      if (ctx != null && ctx.mounted) {
        await showPushPermissionRationaleDialog(ctx);
        await _prefs.setBool(kPushPermissionRationaleSeenKey, true);
        if (!_isMounted()) {
          return;
        }
      }
    }

    if (kDebugMode) {
      AppLog.verbose(
        '[Push] Showing system notification permission (required for '
        'Settings → Notifications and visible push banners).',
      );
    }
    await _push.requestSystemNotificationPermission();
    if (await _push.hasUsableAlertPermission()) {
      await _push.ensureNotificationDeliveryReady();
    }
    if (!await _push.hasUsableAlertPermission()) {
      final AuthorizationStatus status = await _push
          .notificationAuthorizationStatus();
      if (status == AuthorizationStatus.denied) {
        await _prefs.setInt(
          kPushPermissionDeniedAtKey,
          DateTime.now().millisecondsSinceEpoch,
        );
        if (await _push.isNotificationPermissionPermanentlyDenied()) {
          await _promptPushOpenSettingsIfNeeded();
        }
      }
    }
  }

  Future<void> _promptPushOpenSettingsIfNeeded() async {
    if (!_isMounted()) {
      return;
    }
    final BuildContext? ctx = _navigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) {
      return;
    }
    await showPushOpenSettingsDialog(ctx);
  }

  void dispose() {
    _foregroundPushSubscription?.cancel();
    _foregroundPushSubscription = null;
  }
}
