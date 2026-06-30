import 'package:design_system/src/theme/app_colors.dart';
import 'package:design_system/src/theme/app_motion.dart';
import 'package:design_system/src/theme/app_radii.dart';
import 'package:flutter/material.dart';

/// Brief background tint when a list row is opened from a notification (inbox deep link).
class NotificationRowHighlight extends StatefulWidget {
  const NotificationRowHighlight({
    super.key,
    required this.child,
    required this.highlighted,
  });

  final Widget child;
  final bool highlighted;

  static const Duration highlightDuration = Duration(milliseconds: 1200);

  @override
  State<NotificationRowHighlight> createState() =>
      _NotificationRowHighlightState();
}

class _NotificationRowHighlightState extends State<NotificationRowHighlight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _tintOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: NotificationRowHighlight.highlightDuration,
    );
    _tintOpacity = Tween<double>(
      begin: 0.08,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    if (widget.highlighted) {
      _startHighlight();
    }
  }

  @override
  void didUpdateWidget(NotificationRowHighlight oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.highlighted && !oldWidget.highlighted) {
      _startHighlight();
    }
  }

  void _startHighlight() {
    final bool reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _controller.value = 1;
      return;
    }
    _controller
      ..reset()
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _tintOpacity,
      builder: (BuildContext context, Widget? child) {
        final double opacity = widget.highlighted ? _tintOpacity.value : 0;
        return DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: opacity),
            borderRadius: AppRadii.sm,
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Runs [onHighlight] once after layout when [targetId] is set.
void scheduleNotificationRowHighlight({
  required String? targetId,
  required GlobalKey rowKey,
  required VoidCallback onHighlight,
  Duration delay = AppMotion.fast,
}) {
  if (targetId == null || targetId.isEmpty) return;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Future<void>.delayed(delay, () {
      final BuildContext? ctx = rowKey.currentContext;
      if (ctx == null || !ctx.mounted) return;
      Scrollable.ensureVisible(
        ctx,
        duration: AppMotion.standard,
        curve: AppMotion.smooth,
        alignment: 0.35,
      );
      onHighlight();
    });
  });
}
