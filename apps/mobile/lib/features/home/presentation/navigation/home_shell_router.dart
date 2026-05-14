import 'dart:async';

import 'package:chisto_mobile/core/navigation/app_navigator_key.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/features/events/presentation/screens/events_feed_screen.dart'
    show EventsFeedScreen, EventsFeedScreenState;
import 'package:chisto_mobile/features/home/presentation/screens/feed_site_comments_route_screen.dart';
import 'package:chisto_mobile/features/home/presentation/screens/feed_site_upvoters_route_screen.dart';
import 'package:chisto_mobile/features/home/presentation/screens/pollution_feed_screen.dart';
import 'package:chisto_mobile/features/home/presentation/screens/pollution_map_screen.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/presentation/screens/site_detail_route_screen.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/coach_tour_host.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/home_bottom_nav_bar.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/home_shell_coach_keys.dart';
import 'package:chisto_mobile/features/onboarding/application/coach_tour_controller.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Maps bottom-nav index to shell location.
String homeShellTabIndexToLocation(int index) {
  switch (index.clamp(0, 3)) {
    case 1:
      return '/reports';
    case 2:
      return '/map';
    case 3:
      return '/events';
    case 0:
    default:
      return '/feed';
  }
}

int homeShellLocationToTabIndex(String location) {
  if (location.startsWith('/reports')) {
    return 1;
  }
  if (location.startsWith('/map')) {
    return 2;
  }
  if (location.startsWith('/events')) {
    return 3;
  }
  return 0;
}

/// Full-screen feed sub-routes where the tab bar and central FAB should not show.
bool homeShellShouldHideBottomBar(Uri uri) {
  final List<String> s = uri.pathSegments;
  return s.length >= 3 &&
      s[0] == 'feed' &&
      (s[2] == 'comments' || s[2] == 'upvoters');
}

/// Shell scaffold: bottom navigation, central report FAB, and [StatefulNavigationShell] body.
class HomeShellRouterScaffold extends StatefulWidget {
  const HomeShellRouterScaffold({
    super.key,
    required this.navigationShell,
    required this.shellUri,
    required this.mapPendingSiteFocus,
    required this.feedKey,
    required this.eventsFeedKey,
    required this.reportsPageBuilder,
    required this.onCentralFabPressed,
    required this.isLaunchingReportFlow,
    required this.coachKeys,
    required this.coachTour,
  });

  final StatefulNavigationShell navigationShell;

  /// Current URI within this shell (e.g. `/feed/uuid/comments`).
  final Uri shellUri;
  final ValueNotifier<String?> mapPendingSiteFocus;
  final GlobalKey feedKey;
  final GlobalKey<EventsFeedScreenState> eventsFeedKey;
  final WidgetBuilder reportsPageBuilder;

  /// [tabIndex] is [StatefulNavigationShell.currentIndex] (0 feed, 1 reports, 2 map, 3 events).
  final Future<void> Function(BuildContext context, int tabIndex)
  onCentralFabPressed;
  final bool isLaunchingReportFlow;
  final HomeShellCoachKeys coachKeys;
  final CoachTourController coachTour;

  @override
  State<HomeShellRouterScaffold> createState() =>
      _HomeShellRouterScaffoldState();
}

class _HomeShellRouterScaffoldState extends State<HomeShellRouterScaffold> {
  @override
  Widget build(BuildContext context) {
    final int currentIndex = widget.navigationShell.currentIndex;
    final bool hideBottomBar = homeShellShouldHideBottomBar(widget.shellUri);

    final Widget scaffold = Scaffold(
      backgroundColor: AppColors.appBackground,
      // Keep tab bar + central FAB visually docked; keyboard overlays tab bodies.
      // Full-screen flows (sheets, wizards) use their own [Scaffold] with inset as needed.
      resizeToAvoidBottomInset: false,
      body: widget.navigationShell,
      bottomNavigationBar: hideBottomBar
          ? null
          : Container(
              color: AppColors.panelBackground,
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 64,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: HomeBottomNavBar(
                          currentIndex: currentIndex,
                          onTabSelected: _onTabSelected,
                          navItemKeys: widget.coachKeys.navItemKeys,
                        ),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        top: -30,
                        child: Center(
                          child: KeyedSubtree(
                            key: widget.coachKeys.fabKey,
                            child: _CentralReportButton(
                              enabled: !widget.isLaunchingReportFlow,
                              semanticsLabel: currentIndex == 3
                                  ? AppLocalizations.of(
                                      context,
                                    )!.eventsFeedCreateSemantic
                                  : AppLocalizations.of(
                                      context,
                                    )!.reportListFabLabel,
                              onPressed: () {
                                unawaited(
                                  widget.onCentralFabPressed(
                                    context,
                                    currentIndex,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        scaffold,
        ListenableBuilder(
          listenable: widget.coachTour,
          builder: (BuildContext context, Widget? _) {
            return CoachTourHost(
              controller: widget.coachTour,
              keys: widget.coachKeys,
              navigationShell: widget.navigationShell,
            );
          },
        ),
      ],
    );
  }

  void _onTabSelected(int index) {
    if (index == widget.navigationShell.currentIndex) {
      if (index == 0) {
        final dynamic state = widget.feedKey.currentState;
        if (state != null) {
          state.scrollToTop();
        }
      } else if (index == 3) {
        widget.eventsFeedKey.currentState?.scrollToTop();
      }
      return;
    }
    widget.navigationShell.goBranch(index);
    if (index == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final dynamic state = widget.feedKey.currentState;
        if (state != null) {
          state.scrollToTop();
        }
      });
    } else if (index == 3) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.eventsFeedKey.currentState?.scrollToTop();
        widget.eventsFeedKey.currentState?.silentRefreshIfStale();
      });
    }
  }
}

class _CentralReportButton extends StatefulWidget {
  const _CentralReportButton({
    required this.onPressed,
    required this.semanticsLabel,
    this.enabled = true,
  });

  final VoidCallback onPressed;
  final String semanticsLabel;

  final bool enabled;

  @override
  State<_CentralReportButton> createState() => _CentralReportButtonState();
}

class _CentralReportButtonState extends State<_CentralReportButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: widget.enabled,
      label: widget.semanticsLabel,
      child: GestureDetector(
        onTapDown: widget.enabled
            ? (_) => setState(() => _pressed = true)
            : null,
        onTapUp: widget.enabled
            ? (_) => setState(() => _pressed = false)
            : null,
        onTapCancel: widget.enabled
            ? () => setState(() => _pressed = false)
            : null,
        onTap: () {
          if (!widget.enabled) {
            return;
          }
          widget.onPressed();
        },
        child: AnimatedScale(
          scale: _pressed && widget.enabled ? 0.94 : 1.0,
          duration: AppMotion.xFast,
          curve: AppMotion.standardCurve,
          child: AnimatedOpacity(
            duration: AppMotion.fast,
            opacity: widget.enabled ? 1 : 0.72,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                  BoxShadow(
                    color: AppColors.shadowLight,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: widget.enabled
                  ? const Icon(
                      Icons.add_rounded,
                      color: AppColors.textOnDark,
                      size: 28,
                    )
                  : Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.white,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MapTabPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return Container(
      color: AppColors.appBackground,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.map_outlined,
              size: 48,
              color: AppColors.textMuted.withValues(alpha: 0.4),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.mapTabPlaceholderHint,
              textAlign: TextAlign.center,
              style: AppTypography.emptyStateSubtitle,
            ),
          ],
        ),
      ),
    );
  }
}

/// Builds the nested [GoRouter] for the signed-in home shell (tabs + feed sub-routes).
GoRouter buildHomeShellGoRouter({
  required String initialLocation,
  required ValueNotifier<String?> mapPendingSiteFocus,
  required GlobalKey feedKey,
  required GlobalKey<EventsFeedScreenState> eventsFeedKey,
  required WidgetBuilder reportsPageBuilder,
  required Future<void> Function(BuildContext context, int tabIndex)
  onCentralFabPressed,
  required ValueNotifier<bool> isLaunchingReportFlow,
  Listenable? refreshListenable,
  required HomeShellCoachKeys coachKeys,
  required CoachTourController coachTour,
}) {
  return GoRouter(
    navigatorKey: homeShellGoRouterNavigatorKey,
    refreshListenable: refreshListenable,
    initialLocation: initialLocation,
    routes: <RouteBase>[
      StatefulShellRoute.indexedStack(
        builder:
            (
              BuildContext context,
              GoRouterState state,
              StatefulNavigationShell navigationShell,
            ) {
              return ListenableBuilder(
                listenable: Listenable.merge(<Listenable>[
                  isLaunchingReportFlow,
                  coachTour,
                ]),
                builder: (BuildContext context, Widget? _) {
                  return HomeShellRouterScaffold(
                    navigationShell: navigationShell,
                    shellUri: state.uri,
                    mapPendingSiteFocus: mapPendingSiteFocus,
                    feedKey: feedKey,
                    eventsFeedKey: eventsFeedKey,
                    reportsPageBuilder: reportsPageBuilder,
                    onCentralFabPressed: onCentralFabPressed,
                    isLaunchingReportFlow: isLaunchingReportFlow.value,
                    coachKeys: coachKeys,
                    coachTour: coachTour,
                  );
                },
              );
            },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/feed',
                pageBuilder: (BuildContext context, GoRouterState state) {
                  return NoTransitionPage<void>(
                    key: const ValueKey<String>('branch-feed'),
                    child: PollutionFeedScreen(
                      key: feedKey,
                      coachProfileAvatarKey: coachKeys.profileAvatarKey,
                    ),
                  );
                },
                routes: <RouteBase>[
                  GoRoute(
                    path: ':siteId',
                    parentNavigatorKey: homeShellGoRouterNavigatorKey,
                    builder: (BuildContext context, GoRouterState state) {
                      final String siteId = state.pathParameters['siteId']!;
                      final Object? extra = state.extra;
                      return SiteDetailRouteScreen(
                        siteId: siteId,
                        previewSite: extra is SiteDetailPreviewExtra
                            ? extra.site
                            : extra is PollutionSite
                            ? extra
                            : null,
                      );
                    },
                    routes: <RouteBase>[
                      GoRoute(
                        path: 'comments',
                        parentNavigatorKey: homeShellGoRouterNavigatorKey,
                        builder: (BuildContext context, GoRouterState state) {
                          final String siteId = state.pathParameters['siteId']!;
                          return FeedSiteCommentsRouteScreen(siteId: siteId);
                        },
                      ),
                      GoRoute(
                        path: 'upvoters',
                        parentNavigatorKey: homeShellGoRouterNavigatorKey,
                        builder: (BuildContext context, GoRouterState state) {
                          final String siteId = state.pathParameters['siteId']!;
                          return FeedSiteUpvotersRouteScreen(siteId: siteId);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            preload: true,
            routes: <RouteBase>[
              GoRoute(
                path: '/reports',
                pageBuilder: (BuildContext context, GoRouterState state) {
                  return NoTransitionPage<void>(
                    key: const ValueKey<String>('branch-reports'),
                    child: reportsPageBuilder(context),
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/map',
                pageBuilder: (BuildContext context, GoRouterState state) {
                  return NoTransitionPage<void>(
                    key: const ValueKey<String>('branch-map'),
                    child: _MapBranchPage(
                      mapPendingSiteFocus: mapPendingSiteFocus,
                    ),
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/events',
                pageBuilder: (BuildContext context, GoRouterState state) {
                  return NoTransitionPage<void>(
                    key: const ValueKey<String>('branch-events'),
                    child: EventsFeedScreen(key: eventsFeedKey),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class _MapBranchPage extends StatefulWidget {
  const _MapBranchPage({required this.mapPendingSiteFocus});

  final ValueNotifier<String?> mapPendingSiteFocus;

  @override
  State<_MapBranchPage> createState() => _MapBranchPageState();
}

class _MapBranchPageState extends State<_MapBranchPage> {
  bool _materialized = false;

  @override
  Widget build(BuildContext context) {
    final StatefulNavigationShellState? shellState =
        StatefulNavigationShell.maybeOf(context);
    final bool isMapTab = shellState?.currentIndex == 2;
    if (isMapTab) {
      _materialized = true;
    }
    if (!_materialized) {
      return _MapTabPlaceholder();
    }
    return PollutionMapScreen(
      pendingSiteFocus: widget.mapPendingSiteFocus,
      isActive: isMapTab,
    );
  }
}
