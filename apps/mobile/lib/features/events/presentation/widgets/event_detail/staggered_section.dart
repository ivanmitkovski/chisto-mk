import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_motion.dart';

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
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: Duration(milliseconds: AppMotion.standard.inMilliseconds + delay),
      curve: AppMotion.emphasized,
      builder: (BuildContext context, double value, Widget? child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 10),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
