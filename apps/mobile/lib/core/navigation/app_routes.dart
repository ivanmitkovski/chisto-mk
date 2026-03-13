import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:chisto_mobile/features/auth/presentation/screens/location_screen.dart';
import 'package:chisto_mobile/features/events/presentation/navigation/event_page_transitions.dart';
import 'package:chisto_mobile/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:chisto_mobile/features/auth/presentation/screens/otp_screen.dart';
import 'package:chisto_mobile/features/auth/presentation/screens/sign_in_screen.dart';
import 'package:chisto_mobile/features/auth/presentation/screens/sign_up_screen.dart';
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
  static const String onboarding = '/onboarding';
  static const String signIn = '/auth/sign-in';
  static const String signUp = '/auth/sign-up';
  static const String otp = '/auth/otp';
  static const String location = '/auth/location';
  static const String home = '/home';
  static const String homeEvents = '/home/events';
  static const String newReport = '/reports/new';
  static const String eventsCreate = '/events/create';
  static const String eventsDetail = '/events/detail';
  static const String eventsAttendeeCheckIn = '/events/attendee-check-in';
  static const String eventsOrganizerCheckIn = '/events/organizer-check-in';
  static const String eventsCleanupEvidence = '/events/cleanup-evidence';
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
        final int initialTabIndex =
            settings.arguments is int ? settings.arguments! as int : 0;
        return MaterialPageRoute<void>(
          builder: (_) => HomeShell(initialTabIndex: initialTabIndex),
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
        return EventDetailPageRoute<void>(
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
