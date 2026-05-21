import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_motion.dart';

class AnimatedListItem extends StatelessWidget {
  const AnimatedListItem({
    super.key,
    required this.index,
    required this.child,
    this.slideOffset = 14.0,
    this.perItemMs = 35,
  });

  final int index;
  final Widget child;
  final double slideOffset;
  final int perItemMs;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: AppMotion.staggerDelay(index, perItemMs: perItemMs),
      curve: AppMotion.emphasized,
      builder: (BuildContext context, double value, Widget? child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * slideOffset),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
