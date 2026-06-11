import 'dart:async';

import 'package:chisto_infrastructure/core/providers/app_providers.dart';
import 'package:feature_auth/src/presentation/eula_acceptance_flow.dart';
import 'package:feature_home/src/application/home_shell_controller.dart';
import 'package:feature_home/src/presentation/screens/pollution_feed_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Legacy [MaterialApp.onGenerateRoute] home shell (tests + notification fallbacks).
///
/// Production navigation uses [buildHomeShellStatefulShellRoute] via go_router.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({
    super.key,
    this.initialTabIndex = 0,
    this.mapSiteIdToFocus,
    this.startCoachTour = false,
  });

  final int initialTabIndex;
  final String? mapSiteIdToFocus;
  final bool startCoachTour;

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  @override
  void initState() {
    super.initState();
    ref
        .read(homeShellControllerProvider.notifier)
        .applyInitialFocus(
          mapSiteIdToFocus: widget.mapSiteIdToFocus,
          startCoachTour: widget.startCoachTour,
        );
  }

  @override
  Widget build(BuildContext context) {
    final HomeShellController shell = ref.read(
      homeShellControllerProvider.notifier,
    );
    return HomeShellBootstrap(
      mapSiteIdToFocus: widget.mapSiteIdToFocus,
      startCoachTour: widget.startCoachTour,
      child: PollutionFeedScreen(key: shell.feedKey),
    );
  }
}

/// Side effects for the signed-in shell: EULA gate and optional coach / map focus.
class HomeShellBootstrap extends ConsumerStatefulWidget {
  const HomeShellBootstrap({
    super.key,
    required this.child,
    this.mapSiteIdToFocus,
    this.startCoachTour = false,
  });

  final Widget child;
  final String? mapSiteIdToFocus;
  final bool startCoachTour;

  @override
  ConsumerState<HomeShellBootstrap> createState() => _HomeShellBootstrapState();
}

class _HomeShellBootstrapState extends ConsumerState<HomeShellBootstrap> {
  @override
  void initState() {
    super.initState();
    ref
        .read(homeShellControllerProvider.notifier)
        .applyInitialFocus(
          mapSiteIdToFocus: widget.mapSiteIdToFocus,
          startCoachTour: widget.startCoachTour,
        );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await ensureCommunityGuidelinesAccepted(context, ref);
    });
  }

  @override
  void didUpdateWidget(HomeShellBootstrap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final String? newFocus = widget.mapSiteIdToFocus?.trim();
    final String? oldFocus = oldWidget.mapSiteIdToFocus?.trim();
    if (newFocus != null &&
        newFocus.isNotEmpty &&
        newFocus != (oldFocus ?? '')) {
      ref
          .read(homeShellControllerProvider.notifier)
          .applyInitialFocus(mapSiteIdToFocus: newFocus);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
