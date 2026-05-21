import 'package:shared_preferences/shared_preferences.dart';

const String kMarketingOnboardingCompletedKey = 'marketing_onboarding_completed_v1';

class MarketingOnboardingStore {
  MarketingOnboardingStore(this._prefs);

  final SharedPreferences _prefs;

  bool get isCompleted => _prefs.getBool(kMarketingOnboardingCompletedKey) ?? false;

  Future<void> markCompleted() =>
      _prefs.setBool(kMarketingOnboardingCompletedKey, true);
}
