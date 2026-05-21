import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_motion.dart';

/// Cross-fades between phases (e.g. skeleton → content → error) with a short
/// fade and subtle scale-in from the top (iOS-style). Used for the profile tab,
/// points history, and weekly rankings so loading transitions stay consistent.
class AnimatedPhaseSwitcher extends StatelessWidget {
  const AnimatedPhaseSwitcher({
    super.key,
    required this.phaseKey,
    required this.child,
    this.duration = AppMotion.emphasizedDuration,
  });

  /// Must change when the visual phase changes (e.g. `'loading'`, `'content'`).
  final Object phaseKey;
  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: AppMotion.smooth,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
        return Stack(
          alignment: Alignment.topCenter,
          fit: StackFit.expand,
          clipBehavior: Clip.none,
          children: <Widget>[
            ...previousChildren,
            ?currentChild,
          ],
        );
      },
      transitionBuilder: (Widget child, Animation<double> animation) {
        final Animation<double> curved = CurvedAnimation(
          parent: animation,
          curve: AppMotion.smooth,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.988, end: 1.0).animate(curved),
            alignment: Alignment.topCenter,
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<Object>(phaseKey),
        child: child,
      ),
    );
  }
}
