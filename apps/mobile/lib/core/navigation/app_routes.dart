import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:chisto_mobile/features/auth/presentation/screens/location_screen.dart';
import 'package:chisto_mobile/features/events/presentation/navigation/event_page_transitions.dart';
import 'package:chisto_mobile/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:chisto_mobile/features/auth/presentation/screens/otp_screen.dart';
import 'package:chisto_mobile/features/auth/presentation/screens/forgot_password_new_screen.dart';
import 'package:chisto_mobile/features/auth/presentation/screens/forgot_password_otp_screen.dart';
import 'package:chisto_mobile/features/auth/presentation/screens/forgot_password_request_screen.dart';
import 'package:chisto_mobile/features/auth/presentation/screens/forgot_password_success_screen.dart';
import 'package:chisto_mobile/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:chisto_mobile/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:chisto_mobile/features/auth/presentation/constants/splash_constants.dart';
import 'package:chisto_mobile/features/auth/presentation/screens/initial_route_screen.dart';
import 'package:chisto_mobile/features/auth/presentation/screens/splash_screen.dart';
import 'package:chisto_mobile/features/events/domain/models/eco_event.dart';
import 'package:chisto_mobile/features/events/presentation/screens/attendee_qr_scanner_screen.dart';
import 'package:chisto_mobile/features/events/presentation/screens/create_event_sheet.dart';
import 'package:chisto_mobile/features/events/presentation/screens/event_cleanup_evidence_screen.dart';
import 'package:chisto_mobile/features/events/presentation/screens/event_detail_screen.dart';
import 'package:chisto_mobile/features/events/presentation/screens/organizer_checkin_screen.dart';
import 'package:chisto_mobile/features/home/presentation/screens/home_shell.dart';
import 'package:chisto_mobile/features/reports/presentation/screens/new_report_screen.dart';
import 'package:image_picker/image_picker.dart';

class AppRoutes {
  const AppRoutes._();

  static const String splash = '/';
  static const String initialRoute = '/initial';
  static const String onboarding = '/onboarding';
  static const String signIn = '/auth/sign-in';
  static const String signUp = '/auth/sign-up';
  static const String otp = '/auth/otp';
  static const String forgotPasswordRequest = '/auth/forgot-password';
  static const String forgotPasswordOtp = '/auth/forgot-password/otp';
  static const String forgotPasswordNew = '/auth/forgot-password/new';
  static const String forgotPasswordSuccess = '/auth/forgot-password/success';
  static const String location = '/auth/location';
  static const String home = '/home';
  /// Opens home on the map tab; pass [MapSiteFocusRouteArgs] to focus a site pin.
  static const String homeMapFocus = '/home/map-focus';
  static const String homeEvents = '/home/events';
  static const String newReport = '/reports/new';
  static const String eventsCreate = '/events/create';
  static const String eventsDetail = '/events/detail';
  static const String eventsAttendeeCheckIn = '/events/attendee-check-in';
  static const String eventsOrganizerCheckIn = '/events/organizer-check-in';
  static const String eventsCleanupEvidence = '/events/cleanup-evidence';
}

class ForgotPasswordNewRouteArgs {
  const ForgotPasswordNewRouteArgs({
    required this.phoneNumberE164,
    required this.code,
  });

  final String phoneNumberE164;
  final String code;
}

class EventCreateRouteArguments {
  const EventCreateRouteArguments({
    this.preselectedSiteId,
    this.preselectedSiteName,
    this.preselectedSiteImageUrl,
    this.preselectedSiteDistanceKm,
  });

  final String? preselectedSiteId;
  final String? preselectedSiteName;
  final String? preselectedSiteImageUrl;
  final double? preselectedSiteDistanceKm;
}

class EventRouteArguments {
  const EventRouteArguments({required this.eventId});

  final String eventId;
}

/// Deep link: `Navigator.pushNamed(context, AppRoutes.homeMapFocus, arguments: MapSiteFocusRouteArgs(siteId: id))`.
class MapSiteFocusRouteArgs {
  const MapSiteFocusRouteArgs({required this.siteId});

  final String siteId;
}

/// Prefer this over raw `int` tab index when you need map focus in one place.
class HomeRouteArgs {
  const HomeRouteArgs({this.initialTabIndex = 0, this.mapSiteIdToFocus});

  final int initialTabIndex;
  final String? mapSiteIdToFocus;
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
      case AppRoutes.initialRoute:
        return PageRouteBuilder<void>(
          settings: settings,
          opaque: true,
          transitionDuration: SplashConstants.splashToInitialTransitionDuration,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (_, __, ___) => const InitialRouteScreen(),
          transitionsBuilder: (_, Animation<double> animation, __, Widget child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: child,
            );
          },
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
      case AppRoutes.forgotPasswordRequest:
        return MaterialPageRoute<void>(
          builder: (_) => const ForgotPasswordRequestScreen(),
          settings: settings,
        );
      case AppRoutes.forgotPasswordOtp:
        final String fpPhoneE164 = settings.arguments is String
            ? settings.arguments! as String
            : '+38970123456';
        return MaterialPageRoute<void>(
          builder: (_) => ForgotPasswordOtpScreen(phoneNumberE164: fpPhoneE164),
          settings: settings,
        );
      case AppRoutes.forgotPasswordNew:
        final ForgotPasswordNewRouteArgs fpArgs =
            settings.arguments is ForgotPasswordNewRouteArgs
                ? settings.arguments! as ForgotPasswordNewRouteArgs
                : const ForgotPasswordNewRouteArgs(
                    phoneNumberE164: '+38970123456',
                    code: '',
                  );
        return MaterialPageRoute<void>(
          builder: (_) => ForgotPasswordNewScreen(
            phoneNumberE164: fpArgs.phoneNumberE164,
            code: fpArgs.code,
          ),
          settings: settings,
        );
      case AppRoutes.forgotPasswordSuccess:
        return MaterialPageRoute<void>(
          builder: (_) => const ForgotPasswordSuccessScreen(),
          settings: settings,
        );
      case AppRoutes.location:
        return MaterialPageRoute<void>(
          builder: (_) => const LocationScreen(),
          settings: settings,
        );
      case AppRoutes.home:
        int initialTabIndex = 0;
        String? mapSiteIdToFocus;
        final Object? homeArgs = settings.arguments;
        if (homeArgs is HomeRouteArgs) {
          initialTabIndex = homeArgs.initialTabIndex;
          mapSiteIdToFocus = homeArgs.mapSiteIdToFocus;
        } else if (homeArgs is int) {
          initialTabIndex = homeArgs;
        }
        return MaterialPageRoute<void>(
          builder: (_) => HomeShell(
            initialTabIndex: initialTabIndex,
            mapSiteIdToFocus: mapSiteIdToFocus,
          ),
          settings: settings,
        );
      case AppRoutes.homeMapFocus:
        final Object? a = settings.arguments;
        final String siteId = a is MapSiteFocusRouteArgs
            ? a.siteId
            : (a is String ? a : '');
        return MaterialPageRoute<void>(
          builder: (_) => HomeShell(
            initialTabIndex: 2,
            mapSiteIdToFocus: siteId.isNotEmpty ? siteId : null,
          ),
          settings: settings,
        );
      case AppRoutes.homeEvents:
        return MaterialPageRoute<void>(
          builder: (_) => const HomeShell(initialTabIndex: 3),
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
      case AppRoutes.eventsCreate:
        final EventCreateRouteArguments args =
            settings.arguments is EventCreateRouteArguments
                ? settings.arguments! as EventCreateRouteArguments
                : const EventCreateRouteArguments();
        return EventSheetPageRoute<EcoEvent>(
          builder: (_) => CreateEventSheet(
            preselectedSiteId: args.preselectedSiteId,
            preselectedSiteName: args.preselectedSiteName,
            preselectedSiteImageUrl: args.preselectedSiteImageUrl,
            preselectedSiteDistanceKm: args.preselectedSiteDistanceKm,
          ),
          settings: settings,
        );
      case AppRoutes.eventsDetail:
        final EventRouteArguments args =
            settings.arguments as EventRouteArguments;
        return CupertinoPageRoute<void>(
          builder: (_) => EventDetailScreen(eventId: args.eventId),
          settings: settings,
        );
      case AppRoutes.eventsAttendeeCheckIn:
        final EventRouteArguments args =
            settings.arguments as EventRouteArguments;
        return EventCheckInPageRoute<bool>(
          builder: (_) => AttendeeQrScannerScreen(eventId: args.eventId),
          settings: settings,
        );
      case AppRoutes.eventsOrganizerCheckIn:
        final EventRouteArguments args =
            settings.arguments as EventRouteArguments;
        return EventCheckInPageRoute<void>(
          builder: (_) => OrganizerCheckInScreen(eventId: args.eventId),
          settings: settings,
        );
      case AppRoutes.eventsCleanupEvidence:
        final EventRouteArguments args =
            settings.arguments as EventRouteArguments;
        return CupertinoPageRoute<void>(
          builder: (_) => EventCleanupEvidenceScreen(eventId: args.eventId),
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
