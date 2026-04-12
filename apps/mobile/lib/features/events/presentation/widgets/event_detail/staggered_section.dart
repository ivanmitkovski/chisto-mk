import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';

class StaggeredSection extends StatelessWidget {
  const StaggeredSection({
    super.key,
    required this.delay,
    required this.child,
  });

  final int delay;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bool reduceMotion = MediaQuery.disableAnimationsOf(context);
    final int baseMs = reduceMotion ? 0 : AppMotion.standard.inMilliseconds;
    final Duration duration = Duration(milliseconds: baseMs + (reduceMotion ? 0 : delay));

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: reduceMotion ? 1 : 0, end: 1),
      duration: duration,
      curve: AppMotion.emphasized,
      builder: (BuildContext context, double value, Widget? child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * AppSpacing.sm),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
