import 'package:flutter/material.dart';

import 'package:chisto_mobile/shared/utils/app_haptics.dart';

/// iOS / macOS: native-style overscroll bounce; pull-to-refresh still uses shared
/// [AppRefreshIndicator] (Material chrome) for consistency with the rest of the app.
bool eventsUseCupertinoSystemEffects(BuildContext context) {
  return switch (Theme.of(context).platform) {
    TargetPlatform.iOS || TargetPlatform.macOS => true,
    _ => false,
  };
}

/// Bouncing, always-scrollable lists (pull-to-refresh + short content) with
/// reduced motion respected.
ScrollPhysics eventsListScrollPhysics(BuildContext context) {
  if (MediaQuery.disableAnimationsOf(context)) {
    return const AlwaysScrollableScrollPhysics();
  }
  return const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics());
}

/// [EventDetailScreen] only: same bounce as feed lists. Pull-to-refresh uses
/// [AppRefreshIndicator] app-wide for consistent chrome.
ScrollPhysics eventDetailScrollPhysics(BuildContext context) {
  return eventsListScrollPhysics(context);
}

/// Pull-to-refresh haptics: lighter on iOS/macOS (bouncy scroll already feels tactile).
void eventsPullRefreshHaptic(BuildContext context) {
  if (eventsUseCupertinoSystemEffects(context)) {
    AppHaptics.light(context);
  } else {
    AppHaptics.medium(context);
  }
}
