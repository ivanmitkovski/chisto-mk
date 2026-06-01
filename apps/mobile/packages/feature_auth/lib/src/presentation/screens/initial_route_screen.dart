import 'dart:async';

import 'package:chisto_infrastructure/core/bootstrap/cold_start_coordinator.dart';
import 'package:chisto_infrastructure/core/deep_links/deep_link_router.dart';
import 'package:chisto_infrastructure/core/navigation/app_go_router.dart';
import 'package:chisto_infrastructure/core/navigation/app_navigation.dart';
import 'package:chisto_infrastructure/core/navigation/app_routes.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_auth/src/application/initial_route_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Resolves session then navigates to home (with optional coach tour), or onboarding.
class InitialRouteScreen extends ConsumerStatefulWidget {
  const InitialRouteScreen({super.key});

  @override
  ConsumerState<InitialRouteScreen> createState() => _InitialRouteScreenState();
}

class _InitialRouteScreenState extends ConsumerState<InitialRouteScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_resolveAndNavigate());
    });
  }

  Future<void> _resolveAndNavigate() async {
    await ref.read(initialRouteControllerProvider.notifier).resolveRoute();
    if (!mounted || _navigated || InitialRouteController.pauseNavigation) {
      return;
    }
    _navigateFor(ref.read(initialRouteControllerProvider).destination);
  }

  void _navigateFor(InitialRouteDestination destination) {
    if (_navigated || !mounted || InitialRouteController.pauseNavigation) {
      return;
    }
    _navigated = true;
    switch (destination) {
      case InitialRouteDestination.loading:
        return;
      case InitialRouteDestination.homeWithCoachTour:
        AppNavigation.navigateToHome(
          args: const HomeRouteArgs(startCoachTour: true),
        );
      case InitialRouteDestination.home:
        AppNavigation.navigateToHome();
      case InitialRouteDestination.signIn:
        AppNavigation.goSignIn();
      case InitialRouteDestination.onboarding:
        AppNavigation.goOnboarding();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyColdStartLaunchIntent();
    });
  }

  void _applyColdStartLaunchIntent() {
    final BuildContext? ctx =
        appGoRouter.routerDelegate.navigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) {
      return;
    }
    if (!ColdStartCoordinator.instance.tryApply(
      router: appGoRouter,
      context: ctx,
    )) {
      DeepLinkRouter.replayPendingAuthenticatedRoute(appGoRouter);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Backup if [resolveRoute] completes while this widget is rebuilding.
    ref.listen<InitialRouteState>(initialRouteControllerProvider, (
      InitialRouteState? previous,
      InitialRouteState next,
    ) {
      if (next.destination == InitialRouteDestination.loading) return;
      if (InitialRouteController.pauseNavigation) return;
      _navigateFor(next.destination);
    });

    final InitialRouteDestination destination = ref
        .watch(initialRouteControllerProvider)
        .destination;
    if (destination != InitialRouteDestination.loading &&
        !InitialRouteController.pauseNavigation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateFor(destination);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Semantics(
        label: AppLocalizations.of(context)!.authLoading,
        child: const Center(
          child: AppLoadingIndicator(
            size: AppLoadingIndicatorSize.sm,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }
}
