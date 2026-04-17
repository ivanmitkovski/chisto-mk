import 'package:flutter/material.dart';

class PulsingQRContainer extends StatefulWidget {
  const PulsingQRContainer({
    super.key,
    required this.isActive,
    required this.child,
    this.pulseOnlyNearExpiry = false,
    this.remainingSecondsUntilExpiry,
  });

  final bool isActive;
  final Widget child;

  /// When true, pulse only while [remainingSecondsUntilExpiry] is at most 10.
  final bool pulseOnlyNearExpiry;
  final int? remainingSecondsUntilExpiry;

  @override
  State<PulsingQRContainer> createState() => _PulsingQRContainerState();
}

class _PulsingQRContainerState extends State<PulsingQRContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.01).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return widget.child;
    }
    if (widget.pulseOnlyNearExpiry) {
      final int? sec = widget.remainingSecondsUntilExpiry;
      if (sec == null || sec > 10) {
        return widget.child;
      }
    }
    if (MediaQuery.disableAnimationsOf(context)) {
      return widget.child;
    }
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (BuildContext context, Widget? child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
