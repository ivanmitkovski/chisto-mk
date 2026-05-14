import 'package:chisto_mobile/features/onboarding/domain/feature_guide_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// [SharedPreferences] persistence for feature guide completion, scoped per user id.
class SharedPrefsFeatureGuideRepository implements FeatureGuideRepository {
  SharedPrefsFeatureGuideRepository(
    this._prefs, {
    required String? Function() currentUserId,
  }) : _currentUserId = currentUserId;

  final SharedPreferences _prefs;
  final String? Function() _currentUserId;

  static const String _completedPrefix = 'feature_guide_completed_v1_';
  static const String _pendingPrefix = 'feature_guide_registration_pending_v1_';

  String _userSuffix() {
    final String? id = _currentUserId()?.trim();
    if (id == null || id.isEmpty) {
      return 'unknown';
    }
    return id;
  }

  String _completedKey() => '$_completedPrefix${_userSuffix()}';

  String _pendingKey() => '$_pendingPrefix${_userSuffix()}';

  @override
  Future<bool> hasCompletedFeatureGuide() async {
    return _prefs.getBool(_completedKey()) ?? false;
  }

  @override
  Future<void> markFeatureGuideCompleted() async {
    await _prefs.setBool(_completedKey(), true);
    await _prefs.remove(_pendingKey());
  }

  @override
  Future<bool> shouldShowPostRegistrationGuide() async {
    final bool pending = _prefs.getBool(_pendingKey()) ?? false;
    final bool completed = _prefs.getBool(_completedKey()) ?? false;
    return pending && !completed;
  }

  @override
  Future<void> markPostRegistrationGuidePending() async {
    if (_userSuffix() == 'unknown') {
      return;
    }
    await _prefs.setBool(_pendingKey(), true);
  }

  @override
  Future<void> clearPostRegistrationGuidePending() async {
    await _prefs.remove(_pendingKey());
  }
}
