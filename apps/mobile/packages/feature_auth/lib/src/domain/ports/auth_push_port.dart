/// Push token lifecycle hooks used during auth session changes.
abstract class AuthPushPort {
  Future<void> unregisterCurrentToken();
  void clearLocalToken();
  Future<void> initialize();
  Future<void> requestNotificationPermissionIfNeeded();
  Future<void> ensureNotificationDeliveryReady();

  Future<void> teardownFirebaseListeners();
}
