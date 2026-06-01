/// Bridges auth session lifecycle to profile avatar UI state.
abstract class ProfileAvatarSync {
  void setRemoteUrl(String? remoteUrl);
  void clearAll();
}

/// Default for unit tests and repositories constructed without UI wiring.
class NoOpProfileAvatarSync implements ProfileAvatarSync {
  const NoOpProfileAvatarSync();

  @override
  void setRemoteUrl(String? remoteUrl) {}

  @override
  void clearAll() {}
}
