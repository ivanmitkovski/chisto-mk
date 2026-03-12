import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

class MapActionsMenu extends StatefulWidget {
  const MapActionsMenu({
    super.key,
    required this.showHeatmap,
    required this.useDarkTiles,
    required this.isLocating,
    required this.locationJustFound,
    required this.rotationLocked,
    required this.onToggleHeatmap,
    required this.onToggleDarkTiles,
    required this.onZoomToFit,
    required this.onToggleRotationLock,
    required this.onLocateMe,
  });

  final bool showHeatmap;
  final bool useDarkTiles;
  final bool isLocating;
  final bool locationJustFound;
  final bool rotationLocked;
  final VoidCallback onToggleHeatmap;
  final VoidCallback onToggleDarkTiles;
  final VoidCallback onZoomToFit;
  final VoidCallback onToggleRotationLock;
  final VoidCallback onLocateMe;

  @override
  State<MapActionsMenu> createState() => _MapActionsMenuState();
}

class _MapActionsMenuState extends State<MapActionsMenu>
    with SingleTickerProviderStateMixin {
  static const Duration _duration = Duration(milliseconds: 320);
  static const int _actionCount = 5;
  static const List<int> _actionOrder = <int>[4, 2, 3, 1, 0];

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _duration,
  );
  late final List<Animation<double>> _itemAnimations =
      List<Animation<double>>.generate(
    _actionCount,
    (int i) => CurvedAnimation(
      parent: _controller,
      curve: Interval(
        i * 0.08,
        (i * 0.08) + 0.45,
        curve: Curves.easeOutCubic,
      ),
    ),
  );

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (_controller.isAnimating) return;
    if (_controller.value > 0.5) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
  }

  Widget _frostedButton({
    required VoidCallback onTap,
    required IconData icon,
    required String semanticLabel,
    Color? iconColor,
    Widget? iconChild,
  }) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.6),
                      width: 1,
                    ),
                  ),
                  child: iconChild ??
                      Icon(
                        icon,
                        size: 20,
                        color: iconColor ?? AppColors.primaryDark,
                      ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        ...List<Widget>.generate(
          _actionCount,
          (int i) {
            final int idx = _actionOrder[i];
            return AnimatedBuilder(
              animation: _controller,
              builder: (BuildContext context, Widget? child) {
                return SizeTransition(
                  sizeFactor: _itemAnimations[idx],
                  axis: Axis.vertical,
                  axisAlignment: 1,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.5),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: _controller,
                      curve: Interval(
                        idx * 0.08,
                        (idx * 0.08) + 0.5,
                        curve: Curves.easeOutCubic,
                      ),
                    )),
                    child: FadeTransition(
                      opacity: _itemAnimations[idx],
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _buildAction(idx),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
        AnimatedRotation(
          turns: _controller.value * 0.125,
          duration: _duration,
          curve: Curves.easeInOutCubic,
          child: _frostedButton(
            onTap: () {
              AppHaptics.light();
              _toggle();
            },
            icon: Icons.apps_rounded,
            semanticLabel: _controller.value > 0.5
                ? 'Close actions menu'
                : 'Open actions menu',
            iconColor: AppColors.primaryDark,
          ),
        ),
      ],
    );
  }

  Widget _buildAction(int index) {
    switch (index) {
      case 0:
        return _frostedButton(
          onTap: widget.onToggleHeatmap,
          icon: Icons.whatshot_rounded,
          semanticLabel:
              widget.showHeatmap ? 'Hide heatmap' : 'Show heatmap',
          iconColor: widget.showHeatmap ? AppColors.primary : AppColors.primaryDark,
        );
      case 1:
        return _frostedButton(
          onTap: widget.onToggleDarkTiles,
          icon: widget.useDarkTiles
              ? Icons.light_mode_rounded
              : Icons.dark_mode_rounded,
          semanticLabel: widget.useDarkTiles
              ? 'Switch to light map'
              : 'Switch to dark map',
        );
      case 2:
        return _frostedButton(
          onTap: widget.onZoomToFit,
          icon: Icons.fit_screen_rounded,
          semanticLabel: 'Zoom out to show whole country',
        );
      case 3:
        return _frostedButton(
          onTap: widget.onToggleRotationLock,
          icon: widget.rotationLocked
              ? Icons.lock_rounded
              : Icons.lock_open_rounded,
          semanticLabel: widget.rotationLocked
              ? 'Unlock map rotation'
              : 'Lock map rotation',
        );
      case 4:
        return _frostedButton(
          onTap: widget.onLocateMe,
          icon: Icons.my_location_rounded,
          semanticLabel: 'Center map on my location',
          iconChild: widget.isLocating
              ? Padding(
                  padding: const EdgeInsets.all(10),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryDark.withValues(alpha: 0.7),
                    ),
                  ),
                )
              : Icon(
                  widget.locationJustFound
                      ? Icons.check_rounded
                      : Icons.my_location_rounded,
                  size: 20,
                  color: widget.locationJustFound
                      ? AppColors.primary
                      : AppColors.primaryDark,
                ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class MapFilterButton extends StatelessWidget {
  const MapFilterButton({
    super.key,
    required this.visibleCount,
    required this.hasFilterActive,
    required this.onTap,
  });

  final int visibleCount;
  final bool hasFilterActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Filter sites. $visibleCount visible. Tap to open filters.',
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.tune_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$visibleCount',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                  ),
                  if (hasFilterActive) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MapSearchIconButton extends StatelessWidget {
  const MapSearchIconButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Search sites',
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.search_rounded,
              size: 20,
              color: AppColors.primaryDark,
            ),
          ),
        ),
      ),
    );
  }
}

class MapCompassButton extends StatelessWidget {
  const MapCompassButton({
    super.key,
    required this.rotationDegrees,
    required this.onReset,
  });

  final double rotationDegrees;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Reset map rotation to north',
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onReset,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TweenAnimationBuilder<double>(
              duration: AppMotion.standard,
              curve: Curves.easeOutCubic,
              tween: Tween<double>(
                begin: -rotationDegrees * (math.pi / 180),
                end: -rotationDegrees * (math.pi / 180),
              ),
              builder: (BuildContext context, double angle, Widget? child) {
                return Transform.rotate(angle: angle, child: child);
              },
              child: const Icon(
                Icons.navigation_rounded,
                size: 20,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
