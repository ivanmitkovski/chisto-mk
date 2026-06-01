import 'package:shared_preferences/shared_preferences.dart';

/// Tracks accepted EULA / community guidelines version for App Store UGC compliance.
///
/// Acceptance is stored per [userId] so sign-out does not force re-acceptance for the
/// same account; use [clearForUser] on account deletion only.
class EulaAcceptanceStore {
  EulaAcceptanceStore(this._prefs);

  /// Legacy device-global key (pre per-user storage).
  static const String acceptedVersionKey = 'chisto_eula_accepted_version_v1';
  static const String currentVersion = '1';

  final SharedPreferences _prefs;

  static String keyForUser(String userId) => '${acceptedVersionKey}_$userId';

  /// One-time migration from the legacy global key to [userId]-scoped storage.
  Future<void> migrateLegacyIfNeeded(String userId) async {
    if (userId.isEmpty) return;
    if (_prefs.getString(keyForUser(userId)) == currentVersion) {
      return;
    }
    if (_prefs.getString(acceptedVersionKey) == currentVersion) {
      await _prefs.setString(keyForUser(userId), currentVersion);
      await _prefs.remove(acceptedVersionKey);
    }
  }

  Future<bool> hasAcceptedForUser(String userId) async {
    if (userId.isEmpty) return false;
    await migrateLegacyIfNeeded(userId);
    return _prefs.getString(keyForUser(userId)) == currentVersion;
  }

  Future<void> acceptForUser(String userId) async {
    if (userId.isEmpty) return;
    await _prefs.setString(keyForUser(userId), currentVersion);
    await _prefs.remove(acceptedVersionKey);
  }

  /// Seeds local cache when the API reports current terms are already accepted.
  Future<void> syncFromServer({
    required String userId,
    required bool requiresTermsAcceptance,
  }) async {
    if (userId.isEmpty || requiresTermsAcceptance) return;
    await acceptForUser(userId);
  }

  Future<void> clearForUser(String userId) async {
    if (userId.isEmpty) return;
    await _prefs.remove(keyForUser(userId));
  }

  /// Clears legacy global key and all per-user keys (tests only).
  Future<void> clearAllForTests() async {
    final Set<String> keys = _prefs.getKeys();
    for (final String key in keys) {
      if (key == acceptedVersionKey ||
          key.startsWith('${acceptedVersionKey}_')) {
        await _prefs.remove(key);
      }
    }
  }
}
