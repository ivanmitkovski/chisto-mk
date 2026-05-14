import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:chisto_mobile/features/auth/presentation/screens/location_screen.dart';
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
import 'package:chisto_mobile/features/events/presentation/screens/event_chat_screen.dart';
import 'package:chisto_mobile/features/events/presentation/screens/event_detail_screen.dart';
import 'package:chisto_mobile/features/events/presentation/screens/event_impact_receipt_screen.dart';
import 'package:chisto_mobile/features/events/presentation/screens/organizer_checkin_screen.dart';
import 'package:chisto_mobile/features/events/presentation/screens/organizer_dashboard_screen.dart';
import 'package:chisto_mobile/core/navigation/unknown_route_screen.dart';
import 'package:chisto_mobile/features/home/presentation/screens/home_shell.dart';
import 'package:chisto_mobile/features/home/presentation/screens/site_detail_route_screen.dart';
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
  static const String featureGuide = '/feature-guide';
  static const String home = '/home';

  /// Opens home on the map tab; pass [MapSiteFocusRouteArgs] to focus a site pin.
  static const String homeMapFocus = '/home/map-focus';
  static const String homeEvents = '/home/events';

  /// Deep link / push: site by id (no hydrated preview).
  static const String siteDetail = '/sites/detail';
  static const String newReport = '/reports/new';
  static const String eventsCreate = '/events/create';
  static const String eventsDetail = '/events/detail';
  static const String eventsAttendeeCheckIn = '/events/attendee-check-in';
  static const String eventsOrganizerCheckIn = '/events/organizer-check-in';
  static const String eventsCleanupEvidence = '/events/cleanup-evidence';
  static const String eventsImpactReceipt = '/events/impact-receipt';
  static const String eventsOrganizerDashboard = '/events/organizer-dashboard';
  static const String eventChat = '/events/chat';
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

class EventChatRouteArguments {
  EventChatRouteArguments({
    required this.eventId,
    required this.eventTitle,
    required this.isOrganizer,
    this.readSyncCompleter,
  });

  final String eventId;
  final String eventTitle;
  final bool isOrganizer;

  /// When set, completed after exit read-sync (see [EventChatScreen.readSyncCompleter]).
  final Completer<void>? readSyncCompleter;
}

/// Deep link: `Navigator.pushNamed(context, AppRoutes.homeMapFocus, arguments: MapSiteFocusRouteArgs(siteId: id))`.
class MapSiteFocusRouteArgs {
  const MapSiteFocusRouteArgs({required this.siteId});

  final String siteId;
}

/// [AppRoutes.siteDetail] arguments.
class SiteDetailByIdRouteArgs {
  const SiteDetailByIdRouteArgs({required this.siteId});

  final String siteId;
}

/// Prefer this over raw `int` tab index when you need map focus in one place.
class HomeRouteArgs {
  const HomeRouteArgs({
    this.initialTabIndex = 0,
    this.mapSiteIdToFocus,
    this.startCoachTour = false,
  });

  final int initialTabIndex;
  final String? mapSiteIdToFocus;
  final bool startCoachTour;
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
          pageBuilder: (_, _, _) => const InitialRouteScreen(),
          transitionsBuilder:
              (_, Animation<double> animation, _, Widget child) {
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
        if (settings.arguments is! String) {
          if (kDebugMode) {
            debugPrint(
              '[AppRouter] AppRoutes.otp expected String phone; got '
              '${settings.arguments?.runtimeType}. Sending user to sign up.',
            );
          }
          return MaterialPageRoute<void>(
            builder: (_) => const SignUpScreen(),
            settings: settings,
          );
        }
        final String phoneNumber = settings.arguments! as String;
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
        if (settings.arguments is! String) {
          if (kDebugMode) {
            debugPrint(
              '[AppRouter] AppRoutes.forgotPasswordOtp expected String; got '
              '${settings.arguments?.runtimeType}. Restarting forgot-password flow.',
            );
          }
          return MaterialPageRoute<void>(
            builder: (_) => const ForgotPasswordRequestScreen(),
            settings: settings,
          );
        }
        final String fpPhoneE164 = settings.arguments! as String;
        return MaterialPageRoute<void>(
          builder: (_) => ForgotPasswordOtpScreen(phoneNumberE164: fpPhoneE164),
          settings: settings,
        );
      case AppRoutes.forgotPasswordNew:
        if (settings.arguments is! ForgotPasswordNewRouteArgs) {
          if (kDebugMode) {
            debugPrint(
              '[AppRouter] AppRoutes.forgotPasswordNew expected ForgotPasswordNewRouteArgs; '
              'got ${settings.arguments?.runtimeType}. Restarting forgot-password flow.',
            );
          }
          return MaterialPageRoute<void>(
            builder: (_) => const ForgotPasswordRequestScreen(),
            settings: settings,
          );
        }
        final ForgotPasswordNewRouteArgs fpArgs =
            settings.arguments! as ForgotPasswordNewRouteArgs;
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
      case AppRoutes.featureGuide:
        return MaterialPageRoute<void>(
          builder: (_) => const HomeShell(startCoachTour: true),
          settings: settings,
        );
      case AppRoutes.home:
        int initialTabIndex = 0;
        String? mapSiteIdToFocus;
        bool startCoachTour = false;
        final Object? homeArgs = settings.arguments;
        if (homeArgs is HomeRouteArgs) {
          initialTabIndex = homeArgs.initialTabIndex;
          mapSiteIdToFocus = homeArgs.mapSiteIdToFocus;
          startCoachTour = homeArgs.startCoachTour;
        } else if (homeArgs is int) {
          initialTabIndex = homeArgs;
        }
        return MaterialPageRoute<void>(
          builder: (_) => HomeShell(
            initialTabIndex: initialTabIndex,
            mapSiteIdToFocus: mapSiteIdToFocus,
            startCoachTour: startCoachTour,
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
      case AppRoutes.siteDetail:
        final Object? siteDetailArgs = settings.arguments;
        final String siteDetailId = siteDetailArgs is SiteDetailByIdRouteArgs
            ? siteDetailArgs.siteId.trim()
            : '';
        if (siteDetailId.isEmpty) {
          return MaterialPageRoute<void>(
            builder: (_) =>
                UnknownRouteScreen(attemptedRouteName: settings.name),
            settings: settings,
          );
        }
        return CupertinoPageRoute<void>(
          builder: (_) => SiteDetailRouteScreen(siteId: siteDetailId),
          settings: settings,
        );
      case AppRoutes.newReport:
        final XFile? photo = settings.arguments is XFile
            ? settings.arguments! as XFile
            : null;
        return MaterialPageRoute<bool>(
          builder: (_) => NewReportScreen(initialPhoto: photo),
          settings: settings,
        );
      case AppRoutes.eventsCreate:
        final EventCreateRouteArguments args =
            settings.arguments is EventCreateRouteArguments
            ? settings.arguments! as EventCreateRouteArguments
            : const EventCreateRouteArguments();
        // CupertinoPageRoute enables iOS edge swipe-back (unlike fullscreen sheet routes).
        return CupertinoPageRoute<EcoEvent?>(
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
        return CupertinoPageRoute<bool>(
          builder: (_) => AttendeeQrScannerScreen(eventId: args.eventId),
          settings: settings,
        );
      case AppRoutes.eventsOrganizerCheckIn:
        final EventRouteArguments args =
            settings.arguments as EventRouteArguments;
        return CupertinoPageRoute<void>(
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
      case AppRoutes.eventsImpactReceipt:
        final EventRouteArguments args =
            settings.arguments as EventRouteArguments;
        return CupertinoPageRoute<void>(
          builder: (_) => EventImpactReceiptScreen(eventId: args.eventId),
          settings: settings,
        );
      case AppRoutes.eventsOrganizerDashboard:
        return CupertinoPageRoute<void>(
          builder: (_) => const OrganizerDashboardScreen(),
          settings: settings,
        );
      case AppRoutes.eventChat:
        final EventChatRouteArguments args =
            settings.arguments is EventChatRouteArguments
            ? settings.arguments! as EventChatRouteArguments
            : EventChatRouteArguments(
                eventId: '',
                eventTitle: '',
                isOrganizer: false,
              );
        return CupertinoPageRoute<void>(
          builder: (_) => EventChatScreen(
            eventId: args.eventId,
            eventTitle: args.eventTitle,
            isOrganizer: args.isOrganizer,
            readSyncCompleter: args.readSyncCompleter,
          ),
          settings: settings,
        );
      default:
        return MaterialPageRoute<void>(
          builder: (_) => UnknownRouteScreen(attemptedRouteName: settings.name),
          settings: settings,
        );
    }
  }

  /// Swaps event detail without a Hero transition between two different `event-thumb-*`
  /// tags (avoids `_HeroFlight.divert` / `manifest.tag == newManifest.tag` crashes).
  static Route<void> eventDetailReplacementRoute(String eventId) {
    return PageRouteBuilder<void>(
      settings: RouteSettings(
        name: AppRoutes.eventsDetail,
        arguments: EventRouteArguments(eventId: eventId),
      ),
      opaque: true,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondary,
          ) => EventDetailScreen(eventId: eventId, enableThumbnailHero: false),
    );
  }
}
