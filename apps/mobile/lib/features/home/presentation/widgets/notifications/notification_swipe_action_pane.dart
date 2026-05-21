import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Icon-only strip revealed behind [NotificationSwipeCard] while dragging.
class NotificationSwipeActionPane extends StatelessWidget {
  const NotificationSwipeActionPane({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.color,
    required this.borderRadius,
  });

  final IconData icon;
  final String semanticLabel;
  final Color color;
  final BorderRadius borderRadius;

  static const double iconSize = 22;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: ClipRRect(
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: borderRadius,
          ),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double maxIcon = math.max(
                0,
                math.min(iconSize, constraints.maxWidth - 8),
              );
              return Center(
                child: Icon(icon, size: maxIcon, color: color),
              );
            },
          ),
        ),
      ),
    );
  }
}
