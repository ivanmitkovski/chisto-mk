import 'package:flutter/material.dart';
import 'package:chisto_mobile/features/auth/presentation/screens/location_screen.dart';
import 'package:chisto_mobile/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:chisto_mobile/features/auth/presentation/screens/otp_screen.dart';
import 'package:chisto_mobile/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:chisto_mobile/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:chisto_mobile/features/auth/presentation/screens/splash_screen.dart';
import 'package:chisto_mobile/features/home/presentation/screens/home_shell.dart';
import 'package:chisto_mobile/features/reports/presentation/screens/new_report_screen.dart';
import 'package:image_picker/image_picker.dart';

class AppRoutes {
  const AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String signIn = '/auth/sign-in';
  static const String signUp = '/auth/sign-up';
  static const String otp = '/auth/otp';
  static const String location = '/auth/location';
  static const String home = '/home';
  static const String newReport = '/reports/new';
}

class AppRouter {
  const AppRouter._();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute<void>(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );
      case AppRoutes.onboarding:
        return MaterialPageRoute<void>(
          builder: (_) => const OnboardingScreen(),
          settings: settings,
        );
      case AppRoutes.signIn:
        return MaterialPageRoute<void>(
          builder: (_) => const SignInScreen(),
          settings: settings,
        );
      case AppRoutes.signUp:
        return MaterialPageRoute<void>(
          builder: (_) => const SignUpScreen(),
          settings: settings,
        );
      case AppRoutes.otp:
        final String phoneNumber = settings.arguments is String
            ? settings.arguments! as String
            : '+389 70 123 456';

        return MaterialPageRoute<void>(
          builder: (_) => OtpScreen(phoneNumber: phoneNumber),
          settings: settings,
        );
      case AppRoutes.location:
        return MaterialPageRoute<void>(
          builder: (_) => const LocationScreen(),
          settings: settings,
        );
      case AppRoutes.home:
        return MaterialPageRoute<void>(
          builder: (_) => const HomeShell(),
          settings: settings,
        );
      case AppRoutes.newReport:
        final XFile? photo = settings.arguments is XFile
            ? settings.arguments! as XFile
            : null;
        return MaterialPageRoute<bool>(
          builder: (_) => NewReportScreen(
            initialPhoto: photo,
            entryLabel: photo != null ? 'Camera report' : 'Guided report',
            entryHint: photo != null
                ? 'Starting from a live photo can speed up moderation because the evidence is already attached.'
                : null,
          ),
          settings: settings,
        );
      default:
        return MaterialPageRoute<void>(
          builder: (_) => const SignInScreen(),
          settings: settings,
        );
    }
  }
}
