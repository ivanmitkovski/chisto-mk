import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/di/service_locator.dart';
import 'package:chisto_mobile/core/navigation/app_routes.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/features/auth/presentation/constants/splash_constants.dart';
import 'package:chisto_mobile/features/onboarding/debug/coach_tour_debug.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';

/// Resolves session then navigates to home (with optional coach tour), or onboarding.
///
/// Shows primary background and a centered spinner while waiting. Session
/// restore is wrapped in a timeout so the app never hangs.
class InitialRouteScreen extends StatefulWidget {
  const InitialRouteScreen({super.key});

  @override
  State<InitialRouteScreen> createState() => _InitialRouteScreenState();
}

class _InitialRouteScreenState extends State<InitialRouteScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _resolveAndNavigate();
  }

  Future<void> _resolveAndNavigate() async {
    final authRepo = ServiceLocator.instance.authRepository;
    final Future<void> sessionFuture = () async {
      try {
        await authRepo.restoreSession();
      } catch (error, stackTrace) {
        if (kDebugMode) {
          debugPrint('[InitialRoute] session restore failed: $error');
          debugPrint('$stackTrace');
        } else {
          debugPrint(
            '[InitialRoute] session restore failed (${error.runtimeType})',
          );
        }
      }
    }();
    final Future<void> timeoutFuture = Future<void>.delayed(
      SplashConstants.initialRouteSessionTimeout,
    );
    final Future<void> minDisplayFuture = Future<void>.delayed(
      SplashConstants.initialRouteMinDisplayTime,
    );

    await Future.wait(<Future<void>>[
      Future.any(<Future<void>>[sessionFuture, timeoutFuture]),
      minDisplayFuture,
    ]);
    if (!mounted || _navigated) return;
    _navigated = true;

    final bool authenticated =
        ServiceLocator.instance.authState.isAuthenticated;
    if (authenticated) {
      final bool showPostRegistrationGuide = await ServiceLocator
          .instance
          .featureGuideRepository
          .shouldShowPostRegistrationGuide();
      if (!mounted) return;
      final bool startCoachTour =
          CoachTourDebug.forceHomeStartCoachArgs || showPostRegistrationGuide;
      if (startCoachTour) {
        Navigator.of(context).pushReplacementNamed(
          AppRoutes.home,
          arguments: const HomeRouteArgs(startCoachTour: true),
        );
      } else {
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
      }
    } else {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Semantics(
        label: AppLocalizations.of(context)!.authLoading,
        child: const Center(
          child: CircularProgressIndicator(
            color: AppColors.white,
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }
}
