import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Root [ProviderContainer] for code outside the widget tree (push background, Workmanager).
ProviderContainer? _rootContainer;

void setRootProviderContainer(ProviderContainer container) {
  _rootContainer = container;
}

void clearRootProviderContainer() {
  _rootContainer = null;
}

ProviderContainer get rootProviderContainer {
  final ProviderContainer? c = _rootContainer;
  if (c == null) {
    throw StateError('rootProviderContainer not set');
  }
  return c;
}

T readRoot<T>(ProviderListenable<T> provider) {
  return rootProviderContainer.read(provider);
}

/// Like [readRoot], but returns null before [setRootProviderContainer].
T? tryReadRoot<T>(ProviderListenable<T> provider) {
  final ProviderContainer? c = _rootContainer;
  if (c == null) {
    return null;
  }
  try {
    return c.read(provider);
    // ignore: avoid_catching_errors, Riverpod throws StateError when the root container is disposed
  } on StateError catch (e) {
    if (e.message.contains('disposed')) {
      return null;
    }
    rethrow;
  }
}
