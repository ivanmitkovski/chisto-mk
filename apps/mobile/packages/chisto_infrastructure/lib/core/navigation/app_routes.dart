import 'dart:async';

import 'package:chisto_infrastructure/core/logging/app_log.dart';
import 'package:chisto_infrastructure/core/navigation/unknown_route_screen.dart';
import 'package:feature_auth/src/domain/models/password_reset_target.dart';
import 'package:feature_auth/src/presentation/constants/splash_constants.dart';
import 'package:feature_auth/src/presentation/screens/forgot_password_new_screen.dart';
import 'package:feature_auth/src/presentation/screens/forgot_password_otp_screen.dart';
import 'package:feature_auth/src/presentation/screens/forgot_password_request_screen.dart';
import 'package:feature_auth/src/presentation/screens/forgot_password_success_screen.dart';
import 'package:feature_auth/src/presentation/screens/initial_route_screen.dart';
import 'package:feature_auth/src/presentation/screens/location_screen.dart';
import 'package:feature_auth/src/presentation/screens/onboarding_screen.dart';
import 'package:feature_auth/src/presentation/screens/otp_screen.dart';
import 'package:feature_auth/src/presentation/screens/sign_in_screen.dart';
import 'package:feature_auth/src/presentation/screens/sign_up_screen.dart';
import 'package:feature_auth/src/presentation/screens/splash_screen.dart';
import 'package:feature_events/src/domain/models/eco_event.dart';
import 'package:feature_events/src/presentation/screens/attendee_qr_scanner_screen.dart';
import 'package:feature_events/src/presentation/screens/create_event_sheet.dart';
import 'package:feature_events/src/presentation/screens/event_chat_screen.dart';
import 'package:feature_events/src/presentation/screens/event_cleanup_evidence_screen.dart';
import 'package:feature_events/src/presentation/screens/event_detail_screen.dart';
import 'package:feature_events/src/presentation/screens/event_impact_receipt_screen.dart';
import 'package:feature_events/src/presentation/screens/organizer_checkin_screen.dart';
import 'package:feature_events/src/presentation/screens/organizer_dashboard_screen.dart';
import 'package:feature_home/src/presentation/screens/home_shell.dart';
import 'package:feature_home/src/presentation/screens/site_detail_route_screen.dart';
import 'package:feature_notifications/src/domain/models/notification_inbox_highlight.dart';
import 'package:feature_reports/src/presentation/screens/new_report_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

  /// Coach tour entry for deep links only; in-app uses [HomeRouteArgs.startCoachTour].
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
    required this.target,
    required this.code,
  });

  final PasswordResetTarget target;
  final String code;
}

/// OTP screen route: [phoneNumberE164] and whether to call `/auth/otp/send` on open.
///
/// Set [requestOtpOnOpen] when the user already has an account but phone is
/// unverified (sign-in, guarded APIs). Leave `false` after registration when
/// the API already sent the code.
class OtpRouteArgs {
  const OtpRouteArgs({
    required this.phoneNumberE164,
    this.requestOtpOnOpen = false,
  });

  final String phoneNumberE164;
  final bool requestOtpOnOpen;
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
  const EventRouteArguments({
    required this.eventId,
    this.enableThumbnailHero = true,
  });

  final String eventId;
  final bool enableThumbnailHero;
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
  const SiteDetailByIdRouteArgs({
    required this.siteId,
    this.initialAction,
    this.initialHighlight,
  });

  final String siteId;
  final String? initialAction;
  final NotificationInboxHighlight? initialHighlight;
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

/// [AppRoutes.newReport] extra payload.
class NewReportRouteExtra {
  const NewReportRouteExtra({
    this.initialPhoto,
    this.entryLabel,
    this.entryHint,
  });

  final XFile? initialPhoto;
  final String? entryLabel;
  final String? entryHint;
}

class AppRouter {
  const AppRouter._();

  static bool _isHomeShellRoute(String? name) {
    return name == AppRoutes.home ||
        name == AppRoutes.homeMapFocus ||
        name == AppRoutes.homeEvents ||
        name == AppRoutes.featureGuide;
  }

  /// Pops to an existing [HomeShell] or pushes one — avoids stacking shells (duplicate GoRouter keys).
  static void navigateToHome(BuildContext context, {Object? arguments}) {
    final NavigatorState nav = Navigator.of(context);
    var found = false;
    nav.popUntil((Route<dynamic> route) {
      if (_isHomeShellRoute(route.settings.name)) {
        found = true;
        return true;
      }
      return route.isFirst;
    });
    if (!found) {
      nav.pushReplacementNamed(AppRoutes.home, arguments: arguments);
    }
  }

  static void navigateToHomeMapFocus(
    BuildContext context, {
    required MapSiteFocusRouteArgs args,
  }) {
    final NavigatorState nav = Navigator.of(context);
    nav.popUntil((Route<dynamic> route) {
      if (_isHomeShellRoute(route.settings.name)) {
        return true;
      }
      return route.isFirst;
    });
    nav.pushReplacementNamed(AppRoutes.homeMapFocus, arguments: args);
  }

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
        late final String phoneNumber;
        late final bool requestOtpOnOpen;
        if (settings.arguments is OtpRouteArgs) {
          final OtpRouteArgs args = settings.arguments! as OtpRouteArgs;
          phoneNumber = args.phoneNumberE164;
          requestOtpOnOpen = args.requestOtpOnOpen;
        } else if (settings.arguments is String) {
          phoneNumber = settings.arguments! as String;
          requestOtpOnOpen = false;
        } else {
          if (kDebugMode) {
            AppLog.warn(
              '[AppRouter] AppRoutes.otp expected String or OtpRouteArgs; got '
              '${settings.arguments?.runtimeType}. Sending user to sign up.',
            );
          }
          return MaterialPageRoute<void>(
            builder: (_) => const SignUpScreen(),
            settings: settings,
          );
        }
        return MaterialPageRoute<void>(
          builder: (_) => OtpScreen(
            phoneNumber: phoneNumber,
            requestOtpOnOpen: requestOtpOnOpen,
          ),
          settings: settings,
        );
      case AppRoutes.forgotPasswordRequest:
        return MaterialPageRoute<void>(
          builder: (_) => const ForgotPasswordRequestScreen(),
          settings: settings,
        );
      case AppRoutes.forgotPasswordOtp:
        if (settings.arguments is! PasswordResetTarget) {
          if (kDebugMode) {
            AppLog.warn(
              '[AppRouter] AppRoutes.forgot_pw_otp expected PasswordResetTarget; got '
              '${settings.arguments?.runtimeType}. Restarting credential recovery flow.',
            );
          }
          return MaterialPageRoute<void>(
            builder: (_) => const ForgotPasswordRequestScreen(),
            settings: settings,
          );
        }
        final PasswordResetTarget fpTarget =
            settings.arguments! as PasswordResetTarget;
        return MaterialPageRoute<void>(
          builder: (_) => ForgotPasswordOtpScreen(target: fpTarget),
          settings: settings,
        );
      case AppRoutes.forgotPasswordNew:
        if (settings.arguments is! ForgotPasswordNewRouteArgs) {
          if (kDebugMode) {
            AppLog.warn(
              '[AppRouter] AppRoutes.forgot_pw_new expected route args; '
              'got ${settings.arguments?.runtimeType}. Restarting credential recovery flow.',
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
            target: fpArgs.target,
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
        final SiteDetailByIdRouteArgs? siteDetailRouteArgs =
            siteDetailArgs is SiteDetailByIdRouteArgs ? siteDetailArgs : null;
        final String siteDetailId = siteDetailRouteArgs?.siteId.trim() ?? '';
        if (siteDetailId.isEmpty) {
          return MaterialPageRoute<void>(
            builder: (_) =>
                UnknownRouteScreen(attemptedRouteName: settings.name),
            settings: settings,
          );
        }
        return CupertinoPageRoute<void>(
          builder: (_) => SiteDetailRouteScreen(
            siteId: siteDetailId,
            initialAction: siteDetailRouteArgs?.initialAction,
            initialHighlight: siteDetailRouteArgs?.initialHighlight,
          ),
          settings: settings,
        );
      case AppRoutes.newReport:
        final XFile? photo = settings.arguments is XFile
            ? settings.arguments! as XFile
            : null;
        return MaterialPageRoute<Object?>(
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
            settings.arguments! as EventRouteArguments;
        return CupertinoPageRoute<void>(
          builder: (_) => EventDetailScreen(eventId: args.eventId),
          settings: settings,
        );
      case AppRoutes.eventsAttendeeCheckIn:
        final EventRouteArguments args =
            settings.arguments! as EventRouteArguments;
        return CupertinoPageRoute<bool>(
          builder: (_) => AttendeeQrScannerScreen(eventId: args.eventId),
          settings: settings,
        );
      case AppRoutes.eventsOrganizerCheckIn:
        final EventRouteArguments args =
            settings.arguments! as EventRouteArguments;
        return CupertinoPageRoute<void>(
          builder: (_) => OrganizerCheckInScreen(eventId: args.eventId),
          settings: settings,
        );
      case AppRoutes.eventsCleanupEvidence:
        final EventRouteArguments args =
            settings.arguments! as EventRouteArguments;
        return CupertinoPageRoute<void>(
          builder: (_) => EventCleanupEvidenceScreen(eventId: args.eventId),
          settings: settings,
        );
      case AppRoutes.eventsImpactReceipt:
        final EventRouteArguments args =
            settings.arguments! as EventRouteArguments;
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
