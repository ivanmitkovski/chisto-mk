import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/features/home/domain/models/pollution_site.dart';
import 'package:chisto_mobile/features/home/presentation/widgets/map/cluster_bucket.dart';

/// Premium animated pin for a single pollution site.
class PollutionMarker extends StatelessWidget {
  const PollutionMarker({
    super.key,
    required this.site,
    required this.isSelected,
    required this.entranceDelay,
    required this.onTap,
  });

  final PollutionSite site;
  final bool isSelected;
  final Duration entranceDelay;
  final VoidCallback onTap;

  static const int _animationMs = 500;

  @override
  Widget build(BuildContext context) {
    final int delayMs = entranceDelay.inMilliseconds;
    final int totalMs = _animationMs + delayMs;
    final double delayFraction = delayMs / totalMs;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: totalMs),
      curve: Curves.easeOutBack,
      tween: Tween<double>(begin: 0, end: 1),
      builder: (BuildContext context, double value, Widget? child) {
        final double entrance = value < delayFraction
            ? 0
            : ((value - delayFraction) / (1 - delayFraction)).clamp(0, 1);
        return Transform.scale(
          scale: entrance,
          child: Opacity(opacity: entrance, child: child),
        );
      },
      child: Semantics(
        button: true,
        label: '${site.title}, ${site.statusLabel} severity',
        child: GestureDetector(
          onTap: onTap,
          child: RepaintBoundary(
            child: AnimatedScale(
            scale: isSelected ? 1.18 : 1.0,
            duration: AppMotion.medium,
            curve: isSelected ? Curves.easeOutBack : Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: AppMotion.medium,
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[
                  if (isSelected)
                    BoxShadow(
                      color: site.statusColor.withValues(alpha: 0.45),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  BoxShadow(
                    color: AppColors.black
                        .withValues(alpha: isSelected ? 0.28 : 0.18),
                    blurRadius: isSelected ? 16 : 8,
                    offset: Offset(0, isSelected ? 8 : 4),
                  ),
                ],
              ),
              child: AnimatedContainer(
                duration: AppMotion.medium,
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: site.statusColor,
                    width: isSelected ? 3.5 : 2.5,
                  ),
                  color: Colors.white,
                ),
                padding: const EdgeInsets.all(2),
                child: ClipOval(
                  child: Image(
                    image: site.imageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Severity-colored pulsing cluster marker.
class ClusterMarker extends StatefulWidget {
  const ClusterMarker({
    super.key,
    required this.bucket,
    required this.count,
    required this.entranceDelay,
    required this.onTap,
  });

  final ClusterBucket bucket;
  final int count;
  final Duration entranceDelay;
  final VoidCallback onTap;

  @override
  State<ClusterMarker> createState() => _ClusterMarkerState();
}

class _ClusterMarkerState extends State<ClusterMarker>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;
  late final AnimationController _tapScaleController;
  late final Animation<double> _tapScale;

  @override
  void initState() {
    super.initState();
    final double intensity = (widget.count / 8).clamp(0.2, 0.6);
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (2800 - intensity * 800).round()),
    )..repeat(reverse: true);
    _pulseScale = Tween<double>(
      begin: 1.0,
      end: 1.0 + 0.04 * intensity,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    _tapScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _tapScale = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _tapScaleController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _tapScaleController.dispose();
    super.dispose();
  }

  static const int _animationMs = 420;

  @override
  Widget build(BuildContext context) {
    final Color dominant = widget.bucket.dominantColor;
    final int count = widget.count;
    final int delayMs = widget.entranceDelay.inMilliseconds;
    final int totalMs = _animationMs + delayMs;
    final double delayFraction = delayMs / totalMs;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: totalMs),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0, end: 1),
      builder: (BuildContext context, double value, Widget? child) {
        final double entrance = value < delayFraction
            ? 0
            : ((value - delayFraction) / (1 - delayFraction)).clamp(0, 1);
        return Transform.scale(
          scale: entrance,
          child: Opacity(opacity: entrance, child: child),
        );
      },
      child: Semantics(
        button: true,
        label:
            '$count pollution site${count == 1 ? '' : 's'} clustered. Tap to expand.',
        child: GestureDetector(
          onTapDown: (_) => _tapScaleController.forward(),
          onTapUp: (_) => _tapScaleController.reverse(),
          onTapCancel: () => _tapScaleController.reverse(),
          onTap: widget.onTap,
          child: AnimatedBuilder(
            animation: Listenable.merge(<Listenable>[_pulseScale, _tapScale]),
            builder: (BuildContext context, Widget? child) {
              return Transform.scale(
                scale: _pulseScale.value * _tapScale.value,
                child: child,
              );
            },
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  center: Alignment.topLeft,
                  radius: 1.2,
                  colors: <Color>[
                    dominant.withValues(alpha: 0.98),
                    dominant.withValues(alpha: 0.85),
                    dominant.withValues(alpha: 0.72),
                  ],
                ),
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.5),
                  width: 2,
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: dominant.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: AppColors.shadowLight,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  count >= 100 ? '99+' : '$count',
                  style: TextStyle(
                    color: AppColors.textOnDark,
                    fontWeight: FontWeight.w700,
                    fontSize: count >= 10 ? 12 : 14,
                    height: 1,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pulsing accuracy ring with animated entrance for user location.
class UserLocationDot extends StatefulWidget {
  const UserLocationDot({super.key});

  @override
  State<UserLocationDot> createState() => _UserLocationDotState();
}

class _UserLocationDotState extends State<UserLocationDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _ringScale;
  late final Animation<double> _ringOpacity;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
    _ringScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    _ringOpacity = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      tween: Tween<double>(begin: 0, end: 1),
      builder: (BuildContext context, double entrance, Widget? child) {
        return Transform.scale(scale: entrance, child: child);
      },
      child: Semantics(
        label: 'Your current location',
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            AnimatedBuilder(
              animation: _pulseController,
              builder: (BuildContext context, Widget? child) {
                return Transform.scale(
                  scale: _ringScale.value,
                  child: Opacity(
                    opacity: _ringOpacity.value,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.primaryDark,
                          width: 2.5,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            AnimatedBuilder(
              animation: _pulseController,
              builder: (BuildContext context, Widget? child) {
                return Transform.scale(
                  scale: 0.4 + 0.15 * _ringScale.value,
                  child: Opacity(
                    opacity: 0.12 + 0.08 * (1 - _ringOpacity.value),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              },
            ),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 3),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: AppColors.primaryDark.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
