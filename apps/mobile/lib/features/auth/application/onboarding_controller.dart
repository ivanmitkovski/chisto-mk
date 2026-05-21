import 'package:chisto_mobile/core/providers/app_providers.dart';
import 'package:chisto_mobile/features/auth/data/marketing_onboarding_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingController extends Notifier<void> {
  @override
  void build() {}

  MarketingOnboardingStore get _store =>
      MarketingOnboardingStore(ref.read(preferencesProvider));

  Future<void> completeOnboarding() => _store.markCompleted();

  Locale? get localeOverride => ref.read(appLocaleOverrideProvider);
}

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, void>(OnboardingController.new);
