import 'package:flutter/material.dart';

import 'package:chisto_mobile/features/home/presentation/widgets/site_card/site_upvote_motion.dart';

/// Digit label with an optional subtle bump when [value] changes (upvote counter).
class SiteEngagementAnimatedNumber extends StatefulWidget {
  const SiteEngagementAnimatedNumber({
    super.key,
    required this.value,
    required this.style,
    this.enableBump = true,
  });

  final int value;
  final TextStyle style;
  final bool enableBump;

  @override
  State<SiteEngagementAnimatedNumber> createState() =>
      _SiteEngagementAnimatedNumberState();
}

class _SiteEngagementAnimatedNumberState extends State<SiteEngagementAnimatedNumber>
    with SingleTickerProviderStateMixin {
  late AnimationController _bump;

  @override
  void initState() {
    super.initState();
    _bump = AnimationController(
      vsync: this,
      duration: SiteUpvoteMotion.countBumpDuration,
    )..addStatusListener((AnimationStatus s) {
        if (s == AnimationStatus.completed) {
          _bump.reset();
        }
      });
  }

  @override
  void didUpdateWidget(covariant SiteEngagementAnimatedNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && widget.enableBump) {
      if (SiteUpvoteMotion.microAnimationsEnabled(context)) {
        _bump.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _bump.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool motion = SiteUpvoteMotion.microAnimationsEnabled(context) &&
        widget.enableBump;
    if (!motion) {
      return Text('${widget.value}', style: widget.style);
    }
    return AnimatedBuilder(
      animation: _bump,
      builder: (BuildContext context, Widget? child) {
        final double t = Curves.easeOutCubic.transform(_bump.value);
        final double scale = 1.0 + 0.08 * (4 * t * (1.0 - t));
        return Transform.scale(
          scale: scale,
          alignment: Alignment.centerLeft,
          child: child,
        );
      },
      child: Text(
        '${widget.value}',
        key: ValueKey<int>(widget.value),
        style: widget.style,
      ),
    );
  }
}
