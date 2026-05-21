import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Root [ProviderContainer] for code outside the widget tree (push background, Workmanager).
ProviderContainer? _rootContainer;

void setRootProviderContainer(ProviderContainer container) {
  _rootContainer = container;
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
