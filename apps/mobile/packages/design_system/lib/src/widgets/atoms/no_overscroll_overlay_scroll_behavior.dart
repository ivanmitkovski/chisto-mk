import 'package:flutter/material.dart';

/// Skips [StretchingOverscrollIndicator] / [GlowingOverscrollIndicator] so the
/// scroll viewport does not clip or tint content at the trailing edge (gray or
/// white band over the last rows). Same idea as profile/settings scroll bodies.
class NoOverscrollOverlayScrollBehavior extends MaterialScrollBehavior {
  const NoOverscrollOverlayScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
