import 'package:chisto_infrastructure/core/providers/root_container.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Cross-feature refresh signals (replaces bootstrap [ValueNotifier]s).
final profileRefreshTickProvider = StateProvider<int>((Ref ref) => 0);

final eventsFeedRefreshTickProvider = StateProvider<int>((Ref ref) => 0);

final notificationsInboxRefreshTickProvider = StateProvider<int>(
  (Ref ref) => 0,
);

final notificationsUnreadCountProvider = StateProvider<int>((Ref ref) => 0);

/// Non-null: fixed app language. Null: follow device locale.
final appLocaleOverrideProvider = StateProvider<Locale?>((Ref ref) => null);

void bumpProfileRefresh() {
  readRoot(profileRefreshTickProvider.notifier).update((int v) => v + 1);
}

void bumpEventsFeedRefresh() {
  readRoot(eventsFeedRefreshTickProvider.notifier).update((int v) => v + 1);
}

void bumpNotificationsInboxRefresh() {
  readRoot(
    notificationsInboxRefreshTickProvider.notifier,
  ).update((int v) => v + 1);
}

void setNotificationsUnreadCount(int count) {
  readRoot(notificationsUnreadCountProvider.notifier).state = count;
}

int readNotificationsUnreadCount() {
  return readRoot(notificationsUnreadCountProvider);
}

void setAppLocaleOverride(Locale? locale) {
  readRoot(appLocaleOverrideProvider.notifier).state = locale;
}

Locale? readAppLocaleOverride() {
  return readRoot(appLocaleOverrideProvider);
}
