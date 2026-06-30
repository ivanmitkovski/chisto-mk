import 'dart:ui' as ui;

import 'package:design_system/src/theme/app_colors.dart';
import 'package:design_system/src/theme/app_motion.dart';
import 'package:design_system/src/theme/app_spacing.dart';
import 'package:design_system/src/widgets/atoms/app_empty_state_icon.dart';
import 'package:design_system/src/widgets/atoms/app_text.dart';
import 'package:flutter/material.dart';

/// Tappable dashed drop zone for upload-style empty states.
class AppEmptyStateDropZone extends StatefulWidget {
  const AppEmptyStateDropZone({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.hint,
    required this.onTap,
    this.minHeight = 220,
    this.semanticsLabel,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String? hint;
  final VoidCallback onTap;
  final double minHeight;
  final String? semanticsLabel;

  @override
  State<AppEmptyStateDropZone> createState() => _AppEmptyStateDropZoneState();
}

class _AppEmptyStateDropZoneState extends State<AppEmptyStateDropZone>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _pulseController.value = 1.0;
      } else {
        _pulseController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String effectiveSemantics =
        widget.semanticsLabel ?? '${widget.title}. ${widget.subtitle}';

    return Semantics(
      button: true,
      label: effectiveSemantics,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: FadeTransition(
          opacity: _pulseAnimation,
          child: AnimatedContainer(
            duration: AppMotion.xFast,
            curve: AppMotion.emphasized,
            transform: Matrix4.diagonal3Values(
              _pressed ? 0.98 : 1.0,
              _pressed ? 0.98 : 1.0,
              1,
            ),
            child: CustomPaint(
              painter: _DashedBorderPainter(
                color: AppColors.primary.withValues(alpha: 0.45),
                borderRadius: AppSpacing.radiusXl,
              ),
              child: Container(
                width: double.infinity,
                constraints: BoxConstraints(minHeight: widget.minHeight),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.xl,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    AppEmptyStateIcon(icon: widget.icon),
                    const SizedBox(height: AppSpacing.lg),
                    AppText.emptyTitle(
                      widget.title,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppText.emptySubtitle(
                      widget.subtitle,
                      textAlign: TextAlign.center,
                    ),
                    if (widget.hint != null) ...<Widget>[
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(
                            Icons.touch_app_rounded,
                            size: 14,
                            color: AppColors.primaryDark.withValues(alpha: 0.8),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            widget.hint!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppColors.primaryDark,
                                  fontSize: 13,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({required this.color, required this.borderRadius});

  final Color color;
  final double borderRadius;
  static const double _dashWidth = 6;
  static const double _dashGap = 4;
  static const double _strokeWidth = 1.5;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rRect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(borderRadius),
    );

    final Path path = Path()..addRRect(rRect);
    final List<ui.PathMetric> metrics = path.computeMetrics().toList();
    for (final ui.PathMetric metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final double end = (distance + _dashWidth)
            .clamp(0, metric.length)
            .toDouble();
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += _dashWidth + _dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      color != oldDelegate.color || borderRadius != oldDelegate.borderRadius;
}
