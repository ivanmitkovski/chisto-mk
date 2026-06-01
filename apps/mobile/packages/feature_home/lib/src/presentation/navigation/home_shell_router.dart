import 'dart:async';

import 'package:chisto_infrastructure/core/navigation/app_navigator_key.dart';
import 'package:chisto_infrastructure/l10n/app_localizations.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_events/feature_events.dart';
import 'package:feature_home/src/application/home_shell_controller.dart';
import 'package:feature_home/src/domain/models/pollution_site.dart';
import 'package:feature_home/src/presentation/navigation/feed_shell_route_extras.dart';
import 'package:feature_home/src/presentation/navigation/home_shell_tab_locations.dart';
import 'package:feature_home/src/presentation/screens/feed_site_comments_route_screen.dart';
import 'package:feature_home/src/presentation/screens/feed_site_upvoters_route_screen.dart';
import 'package:feature_home/src/presentation/screens/home_shell.dart';
import 'package:feature_home/src/presentation/screens/pollution_feed_screen.dart';
import 'package:feature_home/src/presentation/screens/pollution_map_screen.dart';
import 'package:feature_home/src/presentation/screens/site_detail_route_screen.dart';
import 'package:feature_home/src/presentation/widgets/home_bottom_nav_bar.dart';
import 'package:feature_notifications/feature_notifications.dart';
import 'package:feature_onboarding/feature_onboarding.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  });

  final StatefulNavigationShell navigationShell;

  /// Current URI within this shell (e.g. `/feed/uuid/comments`).
  final Uri shellUri;
  final ValueNotifier<String?> mapPendingSiteFocus;
  final GlobalKey feedKey;
  final GlobalKey<EventsFeedScreenState> eventsFeedKey;
  final WidgetBuilder reportsPageBuilder;

  final Future<void> Function(BuildContext context) onCentralFabPressed;
  final bool isLaunchingReportFlow;
  final HomeShellCoachKeys coachKeys;

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
          : ColoredBox(
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
                              semanticsLabel: AppLocalizations.of(
                                context,
                              )!.reportListFabLabel,
                              onPressed: () {
                                unawaited(widget.onCentralFabPressed(context));
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
        CoachTourHost(
          keys: widget.coachKeys,
          navigationShell: widget.navigationShell,
        ),
      ],
    );
  }

  void _onTabSelected(int index) {
    if (index == widget.navigationShell.currentIndex) {
      if (index == 0) {
        final dynamic state = widget.feedKey.currentState;
        if (state != null) {
          // ignore: avoid_dynamic_calls, private feed state via raw GlobalKey
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
          // ignore: avoid_dynamic_calls, private feed state via raw GlobalKey
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
                boxShadow: AppShadows.fabPrimary(),
              ),
              child: widget.enabled
                  ? const Icon(
                      Icons.add_rounded,
                      color: AppColors.textOnDark,
                      size: 28,
                    )
                  : const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: AppLoadingIndicator(color: AppColors.white),
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
    final TextTheme textTheme = Theme.of(context).textTheme;
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
              style: AppTypography.emptyStateSubtitle(textTheme),
            ),
          ],
        ),
      ),
    );
  }
}

/// Indexed tab shell for the signed-in home experience (feed, reports, map, events).
StatefulShellRoute buildHomeShellStatefulShellRoute({
  required HomeShellController controller,
}) {
  return StatefulShellRoute.indexedStack(
    builder:
        (
          BuildContext context,
          GoRouterState state,
          StatefulNavigationShell navigationShell,
        ) {
          final GoRouter shellRouter = GoRouter.of(context);
          return Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? _) {
              ref.watch(homeShellControllerProvider);
              ref.watch(coachTourControllerProvider);
              final HomeShellController shell = ref.read(
                homeShellControllerProvider.notifier,
              );
              return HomeShellBootstrap(
                mapSiteIdToFocus: null,
                startCoachTour: false,
                child: ListenableBuilder(
                  listenable: Listenable.merge(<Listenable>[
                    shellRouter.routeInformationProvider,
                  ]),
                  builder: (BuildContext context, Widget? _) {
                    return HomeShellRouterScaffold(
                      navigationShell: navigationShell,
                      shellUri: shellRouter.state.uri,
                      mapPendingSiteFocus: shell.mapPendingSiteFocus,
                      feedKey: shell.feedKey,
                      eventsFeedKey: shell.eventsFeedKey,
                      reportsPageBuilder: shell.buildReportsTab,
                      onCentralFabPressed: (BuildContext ctx) =>
                          shell.handleCentralFabPressed(ctx, ref),
                      isLaunchingReportFlow: shell.isLaunchingReportFlow,
                      coachKeys: shell.coachKeys,
                    );
                  },
                ),
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
                  key: controller.feedKey,
                  coachProfileAvatarKey: controller.coachKeys.profileAvatarKey,
                ),
              );
            },
            routes: <RouteBase>[
              GoRoute(
                path: ':siteId',
                parentNavigatorKey: appRootNavigatorKey,
                builder: (BuildContext context, GoRouterState state) {
                  final String siteId = state.pathParameters['siteId']!;
                  final Object? extra = state.extra;
                  String? initialAction;
                  NotificationInboxHighlight? initialHighlight;
                  PollutionSite? previewSite;
                  int initialTabIndex = 0;
                  if (extra is FeedSiteDetailRouteExtra) {
                    previewSite = extra.previewSite;
                    initialAction = extra.initialAction;
                    initialHighlight = extra.initialHighlight;
                    initialTabIndex = extra.initialTabIndex;
                  } else if (extra is SiteDetailPreviewExtra) {
                    previewSite = extra.site;
                  } else if (extra is PollutionSite) {
                    previewSite = extra;
                  }
                  return SiteDetailRouteScreen(
                    siteId: siteId,
                    previewSite: previewSite,
                    initialAction: initialAction,
                    initialHighlight: initialHighlight,
                    initialTabIndex: initialTabIndex,
                  );
                },
                routes: <RouteBase>[
                  GoRoute(
                    path: 'comments',
                    parentNavigatorKey: appRootNavigatorKey,
                    builder: (BuildContext context, GoRouterState state) {
                      final String siteId = state.pathParameters['siteId']!;
                      final Object? extra = state.extra;
                      final FeedSiteCommentsRouteExtra? commentsExtra =
                          extra is FeedSiteCommentsRouteExtra ? extra : null;
                      return FeedSiteCommentsRouteScreen(
                        siteId: siteId,
                        highlightCommentId: commentsExtra?.highlightCommentId,
                        highlightActorUserId:
                            commentsExtra?.highlightActorUserId,
                      );
                    },
                  ),
                  GoRoute(
                    path: 'upvoters',
                    parentNavigatorKey: appRootNavigatorKey,
                    builder: (BuildContext context, GoRouterState state) {
                      final String siteId = state.pathParameters['siteId']!;
                      final Object? extra = state.extra;
                      final String? highlightUserId =
                          extra is FeedSiteUpvotersRouteExtra
                          ? extra.highlightUserId
                          : null;
                      return FeedSiteUpvotersRouteScreen(
                        siteId: siteId,
                        highlightUserId: highlightUserId,
                      );
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
                child: Builder(builder: controller.buildReportsTab),
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
                  mapPendingSiteFocus: controller.mapPendingSiteFocus,
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
                child: EventsFeedScreen(key: controller.eventsFeedKey),
              );
            },
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
