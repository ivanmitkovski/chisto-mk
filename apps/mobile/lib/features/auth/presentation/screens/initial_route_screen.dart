import 'dart:async';

import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/bootstrap/cold_start_coordinator.dart';
import 'package:chisto_mobile/core/navigation/app_navigator_key.dart';
import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/features/auth/application/initial_route_controller.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/shared/widgets/atoms/app_loading_indicator.dart';
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
    if (!mounted || _navigated) return;
    _navigateFor(ref.read(initialRouteControllerProvider).destination);
  }

  void _navigateFor(InitialRouteDestination destination) {
    if (_navigated || !mounted) return;
    _navigated = true;
    switch (destination) {
      case InitialRouteDestination.loading:
        return;
      case InitialRouteDestination.homeWithCoachTour:
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.home,
          arguments: const HomeRouteArgs(startCoachTour: true),
        );
      case InitialRouteDestination.home:
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
      case InitialRouteDestination.signIn:
        Navigator.of(context).pushReplacementNamed(AppRoutes.signIn);
      case InitialRouteDestination.onboarding:
        Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyColdStartLaunchIntent();
    });
  }

  void _applyColdStartLaunchIntent() {
    final NavigatorState? nav = appRootNavigatorKey.currentState;
    final BuildContext? ctx = appRootNavigatorKey.currentContext;
    if (nav == null || ctx == null || !ctx.mounted) {
      return;
    }
    ColdStartCoordinator.instance.tryApply(navigator: nav, context: ctx);
  }

  @override
  Widget build(BuildContext context) {
    // Backup if [resolveRoute] completes while this widget is rebuilding.
    ref.listen<InitialRouteState>(initialRouteControllerProvider, (
      InitialRouteState? previous,
      InitialRouteState next,
    ) {
      if (next.destination == InitialRouteDestination.loading) return;
      _navigateFor(next.destination);
    });

    final InitialRouteDestination destination =
        ref.watch(initialRouteControllerProvider).destination;
    if (destination != InitialRouteDestination.loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateFor(destination);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Semantics(
        label: AppLocalizations.of(context)!.authLoading,
        child: Center(child: AppLoadingIndicator(
            size: AppLoadingIndicatorSize.sm,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }
}
