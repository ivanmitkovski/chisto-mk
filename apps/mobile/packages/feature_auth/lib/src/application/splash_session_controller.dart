import 'package:chisto_infrastructure/core/logging/app_log.dart';
import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SplashSessionState {
  const SplashSessionState({this.isRestoring = false, this.completed = false});

  final bool isRestoring;
  final bool completed;

  SplashSessionState copyWith({bool? isRestoring, bool? completed}) {
    return SplashSessionState(
      isRestoring: isRestoring ?? this.isRestoring,
      completed: completed ?? this.completed,
    );
  }
}

class SplashSessionController extends Notifier<SplashSessionState> {
  @override
  SplashSessionState build() => const SplashSessionState();

  /// When true (tests/goldens), [restoreSession] runs but does not set completed.
  static bool pauseAfterRestore = false;

  Future<void>? _restoreFuture;

  /// Single in-flight restore shared by splash and initial-route (avoids racing sign-in).
  Future<void> restoreSession() {
    final Future<void>? existing = _restoreFuture;
    if (existing != null) {
      return existing;
    }
    final Future<void> future = _restoreSessionOnce();
    _restoreFuture = future;
    return future;
  }

  Future<void> _restoreSessionOnce() async {
    if (pauseAfterRestore) {
      try {
        await ref.read(authRepositoryProvider).restoreSession();
      } on Object catch (e, st) {
        AppLog.warn('restoreSession (paused) failed', error: e, stackTrace: st);
      }
      return;
    }
    state = state.copyWith(isRestoring: true);
    try {
      await ref.read(authRepositoryProvider).restoreSession();
    } on Object catch (e, st) {
      AppLog.warn('restoreSession failed', error: e, stackTrace: st);
    } finally {
      state = state.copyWith(isRestoring: false, completed: true);
    }
  }
}

final splashSessionControllerProvider =
    NotifierProvider<SplashSessionController, SplashSessionState>(
      SplashSessionController.new,
    );
