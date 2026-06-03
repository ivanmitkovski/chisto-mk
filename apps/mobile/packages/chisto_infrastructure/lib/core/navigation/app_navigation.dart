import 'dart:async';

import 'package:chisto_infrastructure/core/navigation/app_go_router.dart';
import 'package:chisto_infrastructure/core/navigation/app_routes.dart';
import 'package:feature_auth/src/domain/models/password_reset_target.dart';
import 'package:feature_events/src/data/discovery_analytics.dart';
import 'package:feature_events/src/domain/models/eco_event.dart';
import 'package:feature_home/src/application/home_shell_controller.dart';
import 'package:feature_home/src/presentation/navigation/home_shell_tab_locations.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

/// Typed navigation helpers over the root [appGoRouter].
class AppNavigation {
  const AppNavigation._();

  static GoRouter get _router => appGoRouter;

  static void goSplash() => _router.go(AppRoutes.splash);

  static void goInitialRoute() => _router.go(AppRoutes.initialRoute);

  static void goOnboarding() => _router.go(AppRoutes.onboarding);

  static void goSignIn() => _router.go(AppRoutes.signIn);

  static void goSignUp() => _router.go(AppRoutes.signUp);

  static void goOtp(OtpRouteArgs args) =>
      _router.go(AppRoutes.otp, extra: args);

  static Future<void> pushOtp(OtpRouteArgs args) =>
      _router.push<void>(AppRoutes.otp, extra: args);

  static void goOtpPhone(String phoneNumberE164) =>
      _router.go(AppRoutes.otp, extra: phoneNumberE164);

  static void goForgotPasswordRequest() =>
      _router.go(AppRoutes.forgotPasswordRequest);

  static Future<void> pushForgotPasswordRequest() =>
      _router.push<void>(AppRoutes.forgotPasswordRequest);

  static void goForgotPasswordOtp(PasswordResetTarget target) =>
      _router.go(AppRoutes.forgotPasswordOtp, extra: target);

  static Future<void> pushForgotPasswordOtp(PasswordResetTarget target) =>
      _router.push<void>(AppRoutes.forgotPasswordOtp, extra: target);

  static void goForgotPasswordNew(ForgotPasswordNewRouteArgs args) =>
      _router.go(AppRoutes.forgotPasswordNew, extra: args);

  static Future<void> pushForgotPasswordNew(ForgotPasswordNewRouteArgs args) =>
      _router.push<void>(AppRoutes.forgotPasswordNew, extra: args);

  static void goForgotPasswordSuccess() =>
      _router.go(AppRoutes.forgotPasswordSuccess);

  static void goLocation() => _router.go(AppRoutes.location);

  /// Replaces the stack with the signed-in shell (default tab: feed).
  static void navigateToHome({HomeRouteArgs? args}) {
    if (args == null) {
      _router.go('/feed');
      return;
    }
    _router.go(AppRoutes.home, extra: args);
  }

  static void navigateToHomeMapFocus({required MapSiteFocusRouteArgs args}) {
    _router.go(AppRoutes.homeMapFocus, extra: args);
  }

  static void navigateToHomeEvents() {
    _router.go('/events');
  }

  static void navigateToFeatureGuide() {
    _router.go(AppRoutes.featureGuide);
  }

  static void navigateToHomeTab(int tabIndex) {
    _router.go(homeShellTabIndexToLocation(tabIndex));
  }

  static void focusMapSite(String siteId) {
    homeShellController.applyInitialFocus(mapSiteIdToFocus: siteId);
    _router.go('/map');
  }

  static Future<EcoEvent?> pushCreateEvent({
    EventCreateRouteArguments args = const EventCreateRouteArguments(),
  }) {
    return _router.push<EcoEvent?>(AppRoutes.eventsCreate, extra: args);
  }

  static Future<void> pushEventDetail({
    required String eventId,
    bool enableThumbnailHero = true,
  }) {
    unawaited(
      DiscoveryAnalytics.instance.maybeTrack(
        DiscoveryFunnelStep.detailView,
        eventId: eventId,
      ),
    );
    return _router.push<void>(
      '${AppRoutes.eventsDetail}/$eventId',
      extra: EventRouteArguments(
        eventId: eventId,
        enableThumbnailHero: enableThumbnailHero,
      ),
    );
  }

  /// Hero-safe replacement between two event detail screens.
  static void replaceEventDetail({required String eventId}) {
    _router.pushReplacement<void>(
      '${AppRoutes.eventsDetail}/$eventId',
      extra: EventRouteArguments(eventId: eventId, enableThumbnailHero: false),
    );
  }

  static Future<bool?> pushAttendeeCheckIn({required String eventId}) {
    return _router.push<bool>(
      AppRoutes.eventsAttendeeCheckIn,
      extra: EventRouteArguments(eventId: eventId),
    );
  }

  static Future<void> pushOrganizerCheckIn({required String eventId}) {
    return _router.push<void>(
      AppRoutes.eventsOrganizerCheckIn,
      extra: EventRouteArguments(eventId: eventId),
    );
  }

  static Future<void> pushCleanupEvidence({required String eventId}) {
    return _router.push<void>(
      AppRoutes.eventsCleanupEvidence,
      extra: EventRouteArguments(eventId: eventId),
    );
  }

  static Future<void> pushImpactReceipt({required String eventId}) {
    return _router.push<void>(
      AppRoutes.eventsImpactReceipt,
      extra: EventRouteArguments(eventId: eventId),
    );
  }

  static Future<void> pushOrganizerDashboard() {
    return _router.push<void>(AppRoutes.eventsOrganizerDashboard);
  }

  static Future<void> pushEventChat(EventChatRouteArguments args) {
    return _router.push<void>(AppRoutes.eventChat, extra: args);
  }

  static Future<void> pushSiteDetail(SiteDetailByIdRouteArgs args) {
    return _router.push<void>(
      '${AppRoutes.siteDetail}/${args.siteId}',
      extra: args,
    );
  }

  static Future<Object?> pushNewReport({XFile? initialPhoto}) {
    return _router.push<Object?>(AppRoutes.newReport, extra: initialPhoto);
  }

  static void goSignInAndClearStack() {
    _router.go(AppRoutes.signIn);
  }

  static const Set<String> authGatePaths = <String>{
    AppRoutes.splash,
    AppRoutes.initialRoute,
    AppRoutes.onboarding,
    AppRoutes.signIn,
  };

  static bool isOnAuthGateRoute() {
    return authGatePaths.contains(
      _router.routeInformationProvider.value.uri.path,
    );
  }

  static Future<Object?> pushNewReportWizard({
    XFile? initialPhoto,
    String? entryLabel,
    String? entryHint,
  }) {
    return _router.push<Object?>(
      AppRoutes.newReport,
      extra: NewReportRouteExtra(
        initialPhoto: initialPhoto,
        entryLabel: entryLabel,
        entryHint: entryHint,
      ),
    );
  }
}
