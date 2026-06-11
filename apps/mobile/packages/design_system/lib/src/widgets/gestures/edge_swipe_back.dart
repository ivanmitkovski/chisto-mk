import 'package:flutter/material.dart';

/// Left-edge horizontal swipe that mirrors iOS interactive pop when native
/// swipe-back is unavailable (e.g. [PopScope.canPop] is false).
class EdgeSwipeBack extends StatefulWidget {
  const EdgeSwipeBack({
    super.key,
    required this.child,
    required this.onSwipeBack,
    this.enabled = true,
    this.edgeWidth = 20,
    this.minDragDistance = 48,
    this.minFlingVelocity = 300,
  });

  final Widget child;
  final VoidCallback onSwipeBack;
  final bool enabled;

  /// Width of the left hot zone that may begin a back swipe.
  final double edgeWidth;

  /// Minimum rightward drag distance before triggering back.
  final double minDragDistance;

  /// Minimum rightward fling velocity before triggering back.
  final double minFlingVelocity;

  @override
  State<EdgeSwipeBack> createState() => _EdgeSwipeBackState();
}

class _EdgeSwipeBackState extends State<EdgeSwipeBack> {
  double _dragDistance = 0;
  bool _triggered = false;

  void _resetTracking() {
    _dragDistance = 0;
    _triggered = false;
  }

  void _maybeTriggerBack({required double velocity}) {
    if (!widget.enabled || _triggered) {
      return;
    }
    final bool passedDistance = _dragDistance >= widget.minDragDistance;
    final bool passedFling = velocity >= widget.minFlingVelocity;
    if (!passedDistance && !passedFling) {
      return;
    }
    _triggered = true;
    widget.onSwipeBack();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        widget.child,
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: widget.edgeWidth,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: (_) => _resetTracking(),
            onHorizontalDragUpdate: (DragUpdateDetails details) {
              if (!widget.enabled) {
                return;
              }
              final double delta = details.delta.dx;
              if (delta > 0) {
                _dragDistance += delta;
              } else if (delta < 0) {
                _dragDistance = (_dragDistance + delta).clamp(
                  0,
                  double.infinity,
                );
              }
            },
            onHorizontalDragEnd: (DragEndDetails details) {
              _maybeTriggerBack(velocity: details.primaryVelocity ?? 0);
              _resetTracking();
            },
            onHorizontalDragCancel: _resetTracking,
          ),
        ),
      ],
    );
  }
}
