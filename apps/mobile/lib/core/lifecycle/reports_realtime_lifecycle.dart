import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:chisto_mobile/core/providers/reports_providers.dart';
import 'package:chisto_mobile/core/providers/root_container.dart';

/// Forces a reports Socket.IO resync after long background (carrier NAT / suspended sockets).
class ReportsRealtimeLifecycle with WidgetsBindingObserver {
  ReportsRealtimeLifecycle();

  DateTime? _pausedAt;

  void register() {
    WidgetsBinding.instance.addObserver(this);
  }

  void unregister() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
      return;
    }
    if (state == AppLifecycleState.resumed) {
      final DateTime? paused = _pausedAt;
      _pausedAt = null;
      if (paused == null) {
        return;
      }
      if (DateTime.now().difference(paused) > const Duration(seconds: 30)) {
        readRoot(reportsRealtimeServiceProvider).requestReconnect();
        unawaited(readRoot(reportOutboxCoordinatorProvider).scheduleProcess());
      }
    }
  }
}
