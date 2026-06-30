import 'package:chisto_infrastructure/core/providers/notifications_providers.dart';
import 'package:chisto_infrastructure/core/providers/root_container.dart';
import 'package:feature_notifications/src/data/push_pending_drain.dart';
import 'package:flutter/widgets.dart';

/// Refreshes the notifications inbox after background (pushes may arrive while suspended).
class NotificationsInboxLifecycle with WidgetsBindingObserver {
  NotificationsInboxLifecycle();

  void register() {
    WidgetsBinding.instance.addObserver(this);
  }

  void unregister() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-apply iOS presentation options after Settings changes (no token re-register).
      // ignore: discarded_futures
      readRoot(
        pushNotificationServiceProvider,
      ).ensureForegroundPresentationReady();
      // ignore: discarded_futures, fire-and-forget refresh on app resume
      drainAndApplyPendingPushState();
    }
  }
}
