import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:feature_auth/src/application/splash_session_controller.dart';
import 'package:feature_auth/src/data/marketing_onboarding_store.dart';
import 'package:feature_onboarding/feature_onboarding.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum InitialRouteDestination {
  loading,
  homeWithCoachTour,
  home,
  signIn,
  onboarding,
}

class InitialRouteState {
  const InitialRouteState({this.destination = InitialRouteDestination.loading});

  final InitialRouteDestination destination;

  InitialRouteState copyWith({InitialRouteDestination? destination}) {
    return InitialRouteState(destination: destination ?? this.destination);
  }
}

class InitialRouteController extends Notifier<InitialRouteState> {
  @override
  InitialRouteState build() => const InitialRouteState();

  /// When true (tests/goldens), navigation hosts skip immediate redirects.
  static bool pauseNavigation = false;

  Future<void> resolveRoute() async {
    await ref.read(splashSessionControllerProvider.notifier).restoreSession();

    final MarketingOnboardingStore marketing = MarketingOnboardingStore(
      ref.read(preferencesProvider),
    );
    if (!marketing.isCompleted) {
      state = state.copyWith(destination: InitialRouteDestination.onboarding);
      return;
    }

    if (!ref.read(authStateProvider).isAuthenticated) {
      state = state.copyWith(destination: InitialRouteDestination.signIn);
      return;
    }

    final bool startCoachTour =
        CoachTourDebug.forceHomeStartCoachArgs ||
        await ref
            .read(featureGuideRepositoryProvider)
            .shouldShowPostRegistrationGuide();

    state = state.copyWith(
      destination: startCoachTour
          ? InitialRouteDestination.homeWithCoachTour
          : InitialRouteDestination.home,
    );
  }
}

final initialRouteControllerProvider =
    NotifierProvider<InitialRouteController, InitialRouteState>(
      InitialRouteController.new,
    );
