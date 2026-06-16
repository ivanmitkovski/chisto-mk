import 'package:chisto_infrastructure/core/auth/auth_state.dart';
import 'package:chisto_infrastructure/core/logging/app_log.dart';
import 'package:chisto_infrastructure/core/navigation/app_navigation.dart';
import 'package:chisto_infrastructure/core/navigation/app_navigator_key.dart';
import 'package:chisto_infrastructure/core/navigation/app_routes.dart';
import 'package:chisto_infrastructure/core/navigation/unknown_route_screen.dart';
import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:chisto_infrastructure/core/providers/root_container.dart';
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
import 'package:feature_events/src/presentation/navigation/events_routes.dart';
import 'package:feature_home/src/application/home_shell_controller.dart';
import 'package:feature_home/src/presentation/navigation/home_shell_router.dart';
import 'package:feature_home/src/domain/models/pollution_site.dart';
import 'package:feature_home/src/presentation/navigation/home_shell_tab_locations.dart';
import 'package:feature_home/src/presentation/utils/open_mark_site_as_cleaned.dart';
import 'package:feature_home/src/presentation/widgets/report_cleanup_submission_slot.dart';
import 'package:feature_home/src/presentation/screens/site_detail_route_screen.dart';
import 'package:feature_notifications/src/presentation/notifications_inbox/notifications_inbox_screen.dart';
import 'package:feature_profile/src/presentation/screens/profile_points_history_route_screen.dart';
import 'package:feature_reports/src/presentation/screens/new_report_screen.dart';
import 'package:feature_reports/src/presentation/widgets/reports_list/report_sheet_view_model.dart';
import 'package:feature_reports/src/presentation/screens/report_detail_route_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

GoRouter? _appGoRouter;

GoRouter get appGoRouter {
  final GoRouter? router = _appGoRouter;
  if (router == null) {
    throw StateError('appGoRouter not bound');
  }
  return router;
}

void bindAppGoRouter(GoRouter router) {
  _appGoRouter = router;
}

GoRouter buildAppGoRouter({String initialLocation = AppRoutes.splash}) {
  final GoRouter router = GoRouter(
    navigatorKey: appRootNavigatorKey,
    refreshListenable: readRoot(authStateProvider),
    initialLocation: initialLocation,
    redirect: (BuildContext context, GoRouterState state) {
      final String? authRedirect = _unauthenticatedRedirect(state);
      if (authRedirect != null) {
        return authRedirect;
      }
      return _legacyHomeRedirect(state);
    },
    errorBuilder: (BuildContext context, GoRouterState state) {
      return UnknownRouteScreen(attemptedRouteName: state.uri.path);
    },
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (BuildContext context, GoRouterState state) {
          return MaterialPage<void>(
            key: state.pageKey,
            child: const SplashScreen(),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.initialRoute,
        pageBuilder: (BuildContext context, GoRouterState state) {
          return CustomTransitionPage<void>(
            key: state.pageKey,
            opaque: true,
            transitionDuration:
                SplashConstants.splashToInitialTransitionDuration,
            reverseTransitionDuration: Duration.zero,
            child: const InitialRouteScreen(),
            transitionsBuilder:
                (
                  BuildContext context,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation,
                  Widget child,
                ) {
                  return FadeTransition(
                    opacity: CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOut,
                    ),
                    child: child,
                  );
                },
          );
        },
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(path: AppRoutes.signIn, builder: (_, _) => const SignInScreen()),
      GoRoute(path: AppRoutes.signUp, builder: (_, _) => const SignUpScreen()),
      GoRoute(
        path: AppRoutes.otp,
        builder: (_, GoRouterState state) => _buildOtpScreen(state.extra),
      ),
      GoRoute(
        path: AppRoutes.forgotPasswordRequest,
        builder: (_, _) => const ForgotPasswordRequestScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPasswordOtp,
        builder: (_, GoRouterState state) {
          if (state.extra is! PasswordResetTarget) {
            if (kDebugMode) {
              AppLog.warn(
                '[AppGoRouter] ${AppRoutes.forgotPasswordOtp} expected PasswordResetTarget; '
                'got ${state.extra?.runtimeType}. Restarting credential recovery flow.',
              );
            }
            return const ForgotPasswordRequestScreen();
          }
          return ForgotPasswordOtpScreen(
            target: state.extra! as PasswordResetTarget,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.forgotPasswordNew,
        builder: (_, GoRouterState state) =>
            _buildForgotPasswordNewScreen(state.extra),
      ),
      GoRoute(
        path: AppRoutes.forgotPasswordSuccess,
        builder: (_, _) => const ForgotPasswordSuccessScreen(),
      ),
      GoRoute(
        path: AppRoutes.location,
        builder: (_, _) => const LocationScreen(),
      ),
      buildHomeShellStatefulShellRoute(),
      GoRoute(
        path: '${AppRoutes.siteDetail}/:siteId',
        parentNavigatorKey: appRootNavigatorKey,
        pageBuilder: (BuildContext context, GoRouterState state) {
          final String siteId = state.pathParameters['siteId']?.trim() ?? '';
          if (siteId.isEmpty) {
            return MaterialPage<void>(
              key: state.pageKey,
              child: UnknownRouteScreen(attemptedRouteName: state.uri.path),
            );
          }
          final Object? extra = state.extra;
          final SiteDetailByIdRouteArgs? args = extra is SiteDetailByIdRouteArgs
              ? extra
              : null;
          return CupertinoPage<void>(
            key: state.pageKey,
            child: SiteDetailRouteScreen(
              siteId: siteId,
              initialAction: args?.initialAction,
              initialHighlight: args?.initialHighlight,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.newReport,
        parentNavigatorKey: appRootNavigatorKey,
        pageBuilder: (BuildContext context, GoRouterState state) {
          final Object? extra = state.extra;
          XFile? photo;
          String? entryLabel;
          String? entryHint;
          if (extra is NewReportRouteExtra) {
            photo = extra.initialPhoto;
            entryLabel = extra.entryLabel;
            entryHint = extra.entryHint;
          } else if (extra is XFile) {
            photo = extra;
          }
          return MaterialPage<Object?>(
            key: state.pageKey,
            child: NewReportScreen(
              initialPhoto: photo,
              entryLabel: entryLabel,
              entryHint: entryHint,
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.notifications,
        parentNavigatorKey: appRootNavigatorKey,
        pageBuilder: (BuildContext context, GoRouterState state) {
          final Object? extra = state.extra;
          final NotificationsRouteExtra? args = extra is NotificationsRouteExtra
              ? extra
              : null;
          return CupertinoPage<int>(
            key: state.pageKey,
            child: NotificationsScreen(
              availableSites: args?.availableSites ?? const <PollutionSite>[],
            ),
          );
        },
      ),
      GoRoute(
        path: '${AppRoutes.reportDetail}/:reportId',
        parentNavigatorKey: appRootNavigatorKey,
        pageBuilder: (BuildContext context, GoRouterState state) {
          final String reportId =
              state.pathParameters['reportId']?.trim() ?? '';
          if (reportId.isEmpty) {
            return MaterialPage<void>(
              key: state.pageKey,
              child: UnknownRouteScreen(attemptedRouteName: state.uri.path),
            );
          }
          return CupertinoPage<void>(
            key: state.pageKey,
            child: Consumer(
              builder: (BuildContext context, WidgetRef ref, Widget? _) {
                return ReportDetailRouteScreen(
                  reportId: reportId,
                  onMarkSiteAsCleaned: (String siteId, snapshot) =>
                      openMarkSiteAsCleanedFromReport(
                        context: context,
                        ref: ref,
                        siteId: siteId,
                        snapshot: snapshot,
                      ),
                  cleanupSectionBuilder:
                      (
                        BuildContext ctx,
                        String siteId,
                        ReportSheetViewModel report,
                      ) => ReportCleanupSubmissionSlot(
                        siteId: siteId,
                        reportApproved:
                            report.status == ReportSheetStatus.approved,
                        snapshot: report,
                      ),
                );
              },
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.profilePointsHistory,
        parentNavigatorKey: appRootNavigatorKey,
        pageBuilder: (BuildContext context, GoRouterState state) {
          final ProfilePointsHistoryRouteExtra? args =
              profilePointsHistoryExtraFrom(state.extra);
          return CupertinoPage<void>(
            key: state.pageKey,
            child: ProfilePointsHistoryRouteScreen(
              summaryUser: args?.summaryUser,
            ),
          );
        },
      ),
      ...buildEventsRoutes(),
    ],
  );

  bindAppGoRouter(router);
  return router;
}

String? _unauthenticatedRedirect(GoRouterState state) {
  final AuthState authState = readRoot(authStateProvider);
  if (authState.status != AuthStatus.unauthenticated) {
    return null;
  }
  final String path = state.uri.path;
  if (AppNavigation.isPublicUnauthenticatedPath(path)) {
    return null;
  }
  return AppRoutes.signIn;
}

String? _legacyHomeRedirect(GoRouterState state) {
  final HomeShellController homeShellController = readRoot(
    homeShellControllerProvider.notifier,
  );
  final String path = state.uri.path;
  if (path == AppRoutes.featureGuide) {
    homeShellController.applyInitialFocus(startCoachTour: true);
    return '/feed';
  }
  if (path == AppRoutes.homeMapFocus) {
    _applyMapFocusRedirect(state, homeShellController);
    return '/map';
  }
  if (path == AppRoutes.home) {
    return _homePathRedirect(state, homeShellController: homeShellController);
  }
  if (path == AppRoutes.homeEvents) {
    return '/events';
  }
  return null;
}

String _homePathRedirect(
  GoRouterState state, {
  HomeShellController? homeShellController,
}) {
  int initialTabIndex = 0;
  String? mapSiteIdToFocus;
  bool startCoachTour = false;
  final Object? homeArgs = state.extra;
  if (homeArgs is HomeRouteArgs) {
    initialTabIndex = homeArgs.initialTabIndex;
    mapSiteIdToFocus = homeArgs.mapSiteIdToFocus;
    startCoachTour = homeArgs.startCoachTour;
  } else if (homeArgs is int) {
    initialTabIndex = homeArgs;
  }
  homeShellController?.applyInitialFocus(
    mapSiteIdToFocus: mapSiteIdToFocus,
    startCoachTour: startCoachTour,
  );
  final String? focusId = mapSiteIdToFocus?.trim();
  if (focusId != null && focusId.isNotEmpty && initialTabIndex == 2) {
    return '/map';
  }
  return homeShellTabIndexToLocation(initialTabIndex);
}

void _applyMapFocusRedirect(
  GoRouterState state,
  HomeShellController homeShellController,
) {
  final Object? a = state.extra;
  final String siteId = a is MapSiteFocusRouteArgs
      ? a.siteId
      : (a is String ? a : '');
  if (siteId.trim().isNotEmpty) {
    homeShellController.applyInitialFocus(mapSiteIdToFocus: siteId);
  }
}

Widget _buildOtpScreen(Object? extra) {
  late final String phoneNumber;
  late final bool requestOtpOnOpen;
  late final bool rememberMe;
  if (extra is OtpRouteArgs) {
    phoneNumber = extra.phoneNumberE164;
    requestOtpOnOpen = extra.requestOtpOnOpen;
    rememberMe = extra.rememberMe;
  } else if (extra is String) {
    phoneNumber = extra;
    requestOtpOnOpen = false;
    rememberMe = true;
  } else {
    if (kDebugMode) {
      AppLog.warn(
        '[AppGoRouter] ${AppRoutes.otp} expected String or OtpRouteArgs; got '
        '${extra.runtimeType}. Sending user to sign in.',
      );
    }
    return const SignInScreen();
  }
  return OtpScreen(
    phoneNumber: phoneNumber,
    requestOtpOnOpen: requestOtpOnOpen,
    rememberMe: rememberMe,
  );
}

Widget _buildForgotPasswordNewScreen(Object? extra) {
  if (extra is! ForgotPasswordNewRouteArgs) {
    if (kDebugMode) {
      AppLog.warn(
        '[AppGoRouter] ${AppRoutes.forgotPasswordNew} expected route args; '
        'got ${extra.runtimeType}. Restarting credential recovery flow.',
      );
    }
    return const ForgotPasswordRequestScreen();
  }
  return ForgotPasswordNewScreen(target: extra.target, code: extra.code);
}
