import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chisto_mobile/core/providers/root_container.dart';

/// Session events for global navigation (401, explicit sign-out).
sealed class AuthSessionEvent {
  const AuthSessionEvent();
}

final class AuthUnauthorizedEvent extends AuthSessionEvent {
  const AuthUnauthorizedEvent();
}

final class AuthExplicitSignOutEvent extends AuthSessionEvent {
  const AuthExplicitSignOutEvent();
}

final authSessionEventControllerProvider =
    Provider<StreamController<AuthSessionEvent>>((Ref ref) {
  final StreamController<AuthSessionEvent> controller =
      StreamController<AuthSessionEvent>.broadcast();
  ref.onDispose(controller.close);
  return controller;
});

final authSessionEventStreamProvider = Provider<Stream<AuthSessionEvent>>((Ref ref) {
  return ref.watch(authSessionEventControllerProvider).stream;
});

void emitAuthUnauthorized() {
  readRoot(authSessionEventControllerProvider)
      .add(const AuthUnauthorizedEvent());
}

void emitAuthExplicitSignOut() {
  readRoot(authSessionEventControllerProvider)
      .add(const AuthExplicitSignOutEvent());
}
