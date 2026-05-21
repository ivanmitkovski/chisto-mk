import 'package:flutter/widgets.dart';

import 'package:chisto_mobile/core/providers/notifications_providers.dart';
import 'package:chisto_mobile/core/providers/root_container.dart';
import 'package:chisto_mobile/features/notifications/data/push_pending_drain.dart';

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
      readRoot(pushNotificationServiceProvider)
          .ensureForegroundPresentationReady();
      // ignore: discarded_futures
      drainAndApplyPendingPushState();
    }
  }
}
