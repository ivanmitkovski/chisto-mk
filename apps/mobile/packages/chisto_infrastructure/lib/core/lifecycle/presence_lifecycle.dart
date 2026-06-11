import 'dart:async';

import 'package:chisto_infrastructure/core/presence/presence_service.dart';
import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:chisto_infrastructure/core/providers/root_container.dart';
import 'package:flutter/widgets.dart';

/// Starts/stops presence on auth transitions; immediate heartbeat on resume.
class PresenceLifecycle with WidgetsBindingObserver {
  PresenceLifecycle();

  void register() {
    WidgetsBinding.instance.addObserver(this);
    readRoot(authStateProvider).addListener(_onAuthChanged);
    _syncWithAuth();
  }

  void unregister() {
    WidgetsBinding.instance.removeObserver(this);
    readRoot(authStateProvider).removeListener(_onAuthChanged);
    globalPresenceService?.stop();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final PresenceService? svc = globalPresenceService;
    if (svc == null) return;
    switch (state) {
      case AppLifecycleState.resumed:
        unawaited(svc.onResumed());
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        unawaited(svc.onPaused());
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        break;
    }
  }

  void _onAuthChanged() => _syncWithAuth();

  void _syncWithAuth() {
    final PresenceService? svc = globalPresenceService;
    if (svc == null) return;
    if (readRoot(authStateProvider).isAuthenticated) {
      unawaited(svc.start());
    } else {
      svc.stop();
    }
  }
}
