import 'package:chisto_infrastructure/core/l10n/context_l10n.dart';
import 'package:design_system/design_system.dart';
import 'package:feature_home/src/domain/models/pollution_site.dart';
import 'package:feature_home/src/presentation/widgets/map/cluster_bucket.dart';
import 'package:feature_home/src/presentation/widgets/map/map_site_pin_image.dart';
import 'package:flutter/material.dart';

/// Premium animated pin for a single pollution site.
class PollutionMarker extends StatelessWidget {
  const PollutionMarker({
    super.key,
    required this.site,
    required this.isSelected,
    required this.entranceDelay,
    required this.onTap,
    this.onLongPress,
    this.animate = true,
    this.burstEntrance = false,
  });

  final PollutionSite site;
  final bool isSelected;
  final Duration entranceDelay;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool animate;

  /// When true, uses a punchier spring curve with shorter duration for the
  /// cluster-expansion "burst" effect.
  final bool burstEntrance;

  static const int _animationMs = 500;
  static const int _burstAnimationMs = 380;

  /// Springy overshoot curve for burst entrance (~56% overshoot, iOS-like pop).
  static const Curve _burstCurve = Cubic(0.34, 1.56, 0.64, 1);

  @override
  Widget build(BuildContext context) {
    if (!animate) {
      return _buildMarkerBody(context);
    }
    final int baseMs = burstEntrance ? _burstAnimationMs : _animationMs;
    final int delayMs = entranceDelay.inMilliseconds;
    final int totalMs = baseMs + delayMs;
    final double delayFraction = totalMs > 0 ? delayMs / totalMs : 0;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: totalMs),
      curve: burstEntrance ? _burstCurve : AppMotion.emphasized,
      tween: Tween<double>(begin: 0, end: 1),
      builder: (BuildContext context, double value, Widget? child) {
        final double entrance = value < delayFraction
            ? 0
            : ((value - delayFraction) / (1 - delayFraction)).clamp(0, 1);
        return Transform.scale(
          scale: entrance,
          child: Opacity(opacity: entrance.clamp(0, 1), child: child),
        );
      },
      child: _buildMarkerBody(context),
    );
  }

  Widget _buildMarkerBody(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.mapPinPreviewSemantic(site.title, site.statusLabel),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        onLongPress: onLongPress,
        child: RepaintBoundary(
          child: AnimatedScale(
            scale: isSelected ? 1.18 : 1.0,
            duration: AppMotion.fast,
            curve: AppMotion.spring,
            child: AnimatedContainer(
              duration: AppMotion.medium,
              curve: Curves.easeOutCubic,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: AppShadows.mapSiteMarker(
                  isSelected: isSelected,
                  statusColor: site.statusColor,
                ),
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
                  color: AppColors.white,
                ),
                padding: const EdgeInsets.all(AppSpacing.radiusHandle),
                child: ClipOval(child: MapPinThumbnail(site: site)),
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
    this.animate = true,
    this.pulseEnabled = true,
  });

  final ClusterBucket bucket;
  final int count;
  final Duration entranceDelay;
  final VoidCallback onTap;
  final bool animate;
  final bool pulseEnabled;

  @override
  State<ClusterMarker> createState() => _ClusterMarkerState();
}

class _ClusterMarkerState extends State<ClusterMarker>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseScale;
  late final AnimationController _tapScaleController;
  late final Animation<double> _tapScale;
  late final AnimationController _countSpringController;
  int _displayCount = 0;
  Color _displayColor = AppColors.primary;

  @override
  void initState() {
    super.initState();
    _displayCount = widget.count;
    _displayColor = widget.bucket.dominantColor;
    final double intensity = (widget.count / 8).clamp(0.2, 0.6);
    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (2800 - intensity * 800).round()),
    );
    if (widget.pulseEnabled) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.value = 1;
    }
    _pulseScale = Tween<double>(begin: 1, end: 1.0 + 0.04 * intensity).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _tapScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _tapScale = Tween<double>(begin: 1, end: 1.1).animate(
      CurvedAnimation(parent: _tapScaleController, curve: Curves.easeOut),
    );
    _countSpringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _countSpringController.value = 1;
  }

  @override
  void didUpdateWidget(covariant ClusterMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.count != widget.count) {
      _countSpringController
        ..reset()
        ..forward();
      _displayCount = widget.count;
    }
    final Color nextColor = widget.bucket.dominantColor;
    if (oldWidget.bucket.dominantColor != nextColor) {
      setState(() => _displayColor = nextColor);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _tapScaleController.dispose();
    _countSpringController.dispose();
    super.dispose();
  }

  static const int _animationMs = 420;

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return _buildClusterBody(context);
    }
    final int delayMs = widget.entranceDelay.inMilliseconds;
    final int totalMs = _animationMs + delayMs;
    final double delayFraction = delayMs / totalMs;

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: totalMs),
      curve: AppMotion.smooth,
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
      child: _buildClusterBody(context),
    );
  }

  Widget _buildClusterBody(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Color dominant = _displayColor;
    final int count = _displayCount;
    return Semantics(
      button: true,
      label: context.l10n.mapClusterSemantic(count),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _tapScaleController.forward(),
        onTapUp: (_) => _tapScaleController.reverse(),
        onTapCancel: () => _tapScaleController.reverse(),
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: Listenable.merge(<Listenable>[_pulseScale, _tapScale]),
          builder: (BuildContext context, Widget? child) {
            final double pulseScale = widget.pulseEnabled
                ? _pulseScale.value
                : 1.0;
            return Transform.scale(
              scale: pulseScale * _tapScale.value,
              child: child,
            );
          },
          child: TweenAnimationBuilder<Color?>(
            tween: ColorTween(
              begin: dominant,
              end: widget.bucket.dominantColor,
            ),
            duration: AppMotion.medium,
            curve: AppMotion.smooth,
            builder: (BuildContext context, Color? color, Widget? child) {
              final Color c = color ?? dominant;
              return Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    center: Alignment.topLeft,
                    radius: 1.2,
                    colors: <Color>[
                      c.withValues(alpha: 0.98),
                      c.withValues(alpha: 0.85),
                      c.withValues(alpha: 0.72),
                    ],
                  ),
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.5),
                    width: 2,
                  ),
                  boxShadow: AppShadows.mapClusterDominant(c),
                ),
                child: Center(
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.82, end: 1).animate(
                      CurvedAnimation(
                        parent: _countSpringController,
                        curve: AppMotion.spring,
                      ),
                    ),
                    child: Text(
                      count >= 100 ? '99+' : '$count',
                      style: AppTypography.badgeLabel(textTheme).copyWith(
                        color: AppColors.textOnDark,
                        fontSize: count >= 10 ? 12 : 14,
                        height: 1,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Fading ghost of a cluster during expansion — provides visual continuity
/// as individual pins burst into view from the cluster's former position.
class ClusterGhostMarker extends StatelessWidget {
  const ClusterGhostMarker({
    super.key,
    required this.color,
    required this.count,
  });

  final Color color;
  final int count;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        tween: Tween<double>(begin: 1, end: 0),
        builder: (BuildContext context, double t, Widget? child) {
          return Transform.scale(
            scale: 0.5 + 0.5 * t,
            child: Opacity(opacity: t, child: child),
          );
        },
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.7),
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.35),
              width: 2,
            ),
            boxShadow: AppShadows.mapMarkerGlow(color),
          ),
          child: Center(
            child: Text(
              count >= 100 ? '99+' : '$count',
              style: AppTypography.badgeLabel(textTheme).copyWith(
                color: AppColors.textOnDark.withValues(alpha: 0.9),
                fontSize: count >= 10 ? 12 : 14,
                height: 1,
                letterSpacing: -0.3,
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
  const UserLocationDot({super.key, this.animate = true});

  final bool animate;

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
    );
    if (widget.animate) {
      _pulseController.repeat();
    } else {
      _pulseController.value = 1;
    }
    _ringScale = Tween<double>(
      begin: 0.5,
      end: 1,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));
    _ringOpacity = Tween<double>(
      begin: 0.5,
      end: 0,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return Semantics(
        label: context.l10n.mapUserLocationSemantic,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.white, width: 2),
              ),
            ),
          ],
        ),
      );
    }
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      tween: Tween<double>(begin: 0, end: 1),
      builder: (BuildContext context, double entrance, Widget? child) {
        return Transform.scale(scale: entrance, child: child);
      },
      child: Semantics(
        label: context.l10n.mapUserLocationSemantic,
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
                      decoration: const BoxDecoration(
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
                boxShadow: AppShadows.mapUserLocationPin(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
