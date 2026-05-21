import 'dart:async';

import 'package:chisto_mobile/core/bootstrap/app_bootstrap.dart';
import 'package:chisto_mobile/core/bootstrap/cold_start_coordinator.dart';
import 'package:chisto_mobile/core/providers/app_providers.dart';
import 'package:chisto_mobile/features/auth/application/splash_session_controller.dart';
import 'package:chisto_mobile/features/auth/data/marketing_onboarding_store.dart';
import 'package:chisto_mobile/features/auth/presentation/constants/splash_constants.dart';
import 'package:chisto_mobile/features/onboarding/debug/coach_tour_debug.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum InitialRouteDestination {
  loading,
  home,
  homeWithCoachTour,
  signIn,
  onboarding,
}

class InitialRouteState {
  const InitialRouteState({
    this.destination = InitialRouteDestination.loading,
  });

  final InitialRouteDestination destination;
}

class InitialRouteController extends Notifier<InitialRouteState> {
  @override
  InitialRouteState build() => const InitialRouteState();

  static bool pauseNavigation = false;

  Future<void> resolveRoute() async {
    state = const InitialRouteState(destination: InitialRouteDestination.loading);
    try {
      final Future<void> sessionFuture =
          ref.read(splashSessionControllerProvider.notifier).restoreSession();
      await Future.wait(<Future<void>>[
        Future.any(<Future<void>>[
          sessionFuture,
          Future<void>.delayed(SplashConstants.initialRouteSessionTimeout),
        ]),
        Future<void>.delayed(SplashConstants.initialRouteMinDisplayTime),
      ]);
      try {
        await AppBootstrap.instance.pushNotificationService
            .consumePendingLaunchNotification()
            .timeout(const Duration(seconds: 2));
      } on Object {
        // Never block cold start on FCM / pending-store work.
      }
      ColdStartCoordinator.instance.markSessionReady();
      if (pauseNavigation) return;

      state = await _destinationAfterSession();
    } on Object {
      state = _fallbackDestination();
    }
  }

  Future<InitialRouteState> _destinationAfterSession() async {
    final bool authenticated = ref.read(authStateProvider).isAuthenticated;
    if (authenticated &&
        ref.read(authRepositoryProvider).restoreProfileValidationPending) {
      return const InitialRouteState(destination: InitialRouteDestination.signIn);
    }
    if (authenticated) {
      final bool showGuide = await ref
          .read(featureGuideRepositoryProvider)
          .shouldShowPostRegistrationGuide();
      final bool coach =
          CoachTourDebug.forceHomeStartCoachArgs || showGuide;
      return InitialRouteState(
        destination: coach
            ? InitialRouteDestination.homeWithCoachTour
            : InitialRouteDestination.home,
      );
    }
    final MarketingOnboardingStore store = MarketingOnboardingStore(
      ref.read(preferencesProvider),
    );
    return InitialRouteState(
      destination: store.isCompleted
          ? InitialRouteDestination.signIn
          : InitialRouteDestination.onboarding,
    );
  }

  InitialRouteState _fallbackDestination() {
    if (ref.read(authStateProvider).isAuthenticated &&
        !ref.read(authRepositoryProvider).restoreProfileValidationPending) {
      return const InitialRouteState(destination: InitialRouteDestination.home);
    }
    final MarketingOnboardingStore store = MarketingOnboardingStore(
      ref.read(preferencesProvider),
    );
    return InitialRouteState(
      destination: store.isCompleted
          ? InitialRouteDestination.signIn
          : InitialRouteDestination.onboarding,
    );
  }
}

final initialRouteControllerProvider =
    NotifierProvider<InitialRouteController, InitialRouteState>(
  InitialRouteController.new,
);
