import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/l10n/context_l10n.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/l10n/app_localizations.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';

const double _mapControlTapTargetSize = 48;

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

  Timer? _heatmapRingTimer;
  bool _heatmapRingActive = false;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _duration,
  );
  static const int _maxActions = 5;
  late final List<Animation<double>> _itemAnimations = _buildItemAnimations(
    _controller,
  );

  List<Animation<double>> _buildItemAnimations(AnimationController controller) {
    const double stagger = 0.11;
    return List<Animation<double>>.generate(
      _maxActions,
      (int i) => CurvedAnimation(
        parent: controller,
        curve: Interval(
          i * stagger,
          (i * stagger) + 0.45,
          curve: Curves.easeOutCubic,
        ),
      ),
    );
  }

  Animation<double> _animationAt(int index) {
    if (index < 0 || index >= _itemAnimations.length) {
      return _itemAnimations[_itemAnimations.length - 1];
    }
    return _itemAnimations[index];
  }

  void _pulseHeatmapConfirmationRing() {
    _heatmapRingTimer?.cancel();
    setState(() => _heatmapRingActive = true);
    _heatmapRingTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _heatmapRingActive = false);
      }
    });
  }

  @override
  void dispose() {
    _heatmapRingTimer?.cancel();
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
        color: AppColors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: _mapControlTapTargetSize,
            height: _mapControlTapTargetSize,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_mapControlTapTargetSize / 2),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.useDarkTiles
                        ? AppColors.glassDark.withValues(alpha: 0.45)
                        : AppColors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: widget.useDarkTiles
                          ? AppColors.white.withValues(alpha: 0.18)
                          : AppColors.white.withValues(alpha: 0.6),
                      width: 1,
                    ),
                  ),
                  child:
                      iconChild ??
                      Icon(
                        icon,
                        size: 20,
                        color: iconColor ??
                            (widget.useDarkTiles
                                ? AppColors.textOnDark
                                : AppColors.primaryDark),
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
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.35,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, _) {
          final bool menuOpen = _controller.value > 0.5;
          final AppLocalizations l10n = context.l10n;
          return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            ...List<Widget>.generate(_actionCount, (int i) {
              final int idx = _actionOrder[i];
              return IgnorePointer(
                ignoring: !menuOpen,
                child: ExcludeSemantics(
                  excluding: !menuOpen,
                  child: SizeTransition(
                    sizeFactor: _animationAt(idx),
                    axis: Axis.vertical,
                    axisAlignment: 1,
                    child: SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(0, 0.5),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: _controller,
                              curve: Interval(
                                idx * 0.11,
                                (idx * 0.11) + 0.5,
                                curve: Curves.easeOutCubic,
                              ),
                            ),
                          ),
                      child: FadeTransition(
                        opacity: _animationAt(idx),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _buildAction(context, l10n, idx),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
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
                semanticLabel: menuOpen
                    ? l10n.mapSemanticCloseActionsMenu
                    : l10n.mapSemanticOpenActionsMenu,
                iconColor: widget.useDarkTiles
                    ? AppColors.textOnDark
                    : AppColors.primaryDark,
              ),
            ),
          ],
        );
        },
      ),
    );
  }

  Widget _buildAction(
    BuildContext context,
    AppLocalizations l10n,
    int index,
  ) {
    switch (index) {
      case 0:
        return AnimatedContainer(
          duration: AppMotion.medium,
          curve: AppMotion.smooth,
          padding: EdgeInsets.zero,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: _heatmapRingActive
                  ? AppColors.primary.withValues(alpha: 0.65)
                  : AppColors.transparent,
              width: 2,
            ),
            boxShadow: _heatmapRingActive
                ? <BoxShadow>[
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: _frostedButton(
            onTap: () {
              AppHaptics.softTransition(context);
              final bool enabling = !widget.showHeatmap;
              widget.onToggleHeatmap();
              if (enabling) {
                _pulseHeatmapConfirmationRing();
              }
            },
            icon: Icons.whatshot_rounded,
            semanticLabel: widget.showHeatmap
                ? l10n.mapSemanticHideHeatmap
                : l10n.mapSemanticShowHeatmap,
            iconColor: widget.showHeatmap
                ? AppColors.primary
                : AppColors.primaryDark,
          ),
        );
      case 1:
        return _frostedButton(
          onTap: widget.onToggleDarkTiles,
          icon: widget.useDarkTiles
              ? Icons.light_mode_rounded
              : Icons.dark_mode_rounded,
          semanticLabel: widget.useDarkTiles
              ? l10n.mapSemanticSwitchToLightMap
              : l10n.mapSemanticSwitchToDarkMap,
        );
      case 2:
        return _frostedButton(
          onTap: widget.onZoomToFit,
          icon: Icons.fit_screen_rounded,
          semanticLabel: l10n.mapSemanticZoomWholeCountry,
        );
      case 3:
        return _frostedButton(
          onTap: widget.onToggleRotationLock,
          icon: widget.rotationLocked
              ? Icons.lock_rounded
              : Icons.lock_open_rounded,
          semanticLabel: widget.rotationLocked
              ? l10n.mapSemanticUnlockRotation
              : l10n.mapSemanticLockRotation,
        );
      case 4:
        return AnimatedContainer(
          duration: AppMotion.medium,
          curve: AppMotion.smooth,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: widget.locationJustFound
                ? Border.all(
                    color: AppColors.primary.withValues(alpha: 0.45),
                    width: 3,
                  )
                : null,
          ),
          child: _frostedButton(
          onTap: widget.onLocateMe,
          icon: Icons.my_location_rounded,
          semanticLabel: l10n.mapSemanticCenterOnMyLocation,
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
    this.useDarkTiles = false,
    this.showStaleCacheBadge = false,
  });

  final int visibleCount;
  final bool hasFilterActive;
  final VoidCallback onTap;
  final bool useDarkTiles;
  final bool showStaleCacheBadge;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final bool isEmpty = visibleCount == 0;
    final String counterText = isEmpty
        ? (hasFilterActive ? l10n.mapFilterCountNoMatch : l10n.mapFilterCountNoSites)
        : '$visibleCount';
    final String semanticStatus = isEmpty
        ? (hasFilterActive
              ? l10n.mapFilterButtonSemanticNoMatch
              : l10n.mapFilterButtonSemanticNoSites)
        : l10n.mapFilterButtonSemanticSitesCount(visibleCount);

    final Color fg =
        useDarkTiles ? AppColors.textOnDark : AppColors.textPrimary;
    final Color iconFg =
        useDarkTiles ? AppColors.textOnDarkMuted : AppColors.textSecondary;

    return Semantics(
      button: true,
      label:
          '${l10n.mapFilterButtonSemanticPrefix} $semanticStatus ${l10n.mapFilterButtonSemanticSuffix}',
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: AnimatedContainer(
              duration: AppMotion.medium,
              curve: AppMotion.smooth,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              constraints: const BoxConstraints(minHeight: _mapControlTapTargetSize),
              decoration: BoxDecoration(
                color: hasFilterActive
                    ? AppColors.primary.withValues(alpha: useDarkTiles ? 0.2 : 0.12)
                    : useDarkTiles
                        ? AppColors.glassDark.withValues(alpha: 0.52)
                        : AppColors.white.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: hasFilterActive
                      ? AppColors.primary.withValues(alpha: 0.45)
                      : useDarkTiles
                          ? AppColors.white.withValues(alpha: 0.14)
                          : AppColors.white.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    Icons.tune_rounded,
                    size: 18,
                    color: iconFg,
                  ),
                  const SizedBox(width: 6),
                  AnimatedSwitcher(
                    duration: AppMotion.fast,
                    switchInCurve: AppMotion.smooth,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder:
                        (Widget child, Animation<double> a) => FadeTransition(
                              opacity: a,
                              child: ScaleTransition(scale: a, child: child),
                            ),
                    child: Text(
                      counterText,
                      key: ValueKey<String>(counterText),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: fg,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                    ),
                  ),
                  if (hasFilterActive) ...<Widget>[
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
                  if (showStaleCacheBadge) ...<Widget>[
                    const SizedBox(width: 6),
                    Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: useDarkTiles ? AppColors.textOnDarkMuted : AppColors.textMuted,
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
  const MapSearchIconButton({
    super.key,
    required this.onTap,
    this.useDarkTiles = false,
  });

  final VoidCallback onTap;
  final bool useDarkTiles;

  @override
  Widget build(BuildContext context) {
    final Color bg = useDarkTiles
        ? AppColors.glassDark.withValues(alpha: 0.5)
        : AppColors.white;
    final Color border = useDarkTiles
        ? AppColors.white.withValues(alpha: 0.14)
        : AppColors.white.withValues(alpha: 0.62);
    final Color fg =
        useDarkTiles ? AppColors.textOnDark : AppColors.primaryDark;

    return Semantics(
      button: true,
      label: context.l10n.mapSemanticSearchSites,
      child: Material(
        color: AppColors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            width: _mapControlTapTargetSize,
            height: _mapControlTapTargetSize,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: Border.all(color: border),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(Icons.search_rounded, size: 20, color: fg),
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
    this.useDarkTiles = false,
  });

  final double rotationDegrees;
  final VoidCallback onReset;
  final bool useDarkTiles;

  @override
  Widget build(BuildContext context) {
    final Color bg = useDarkTiles
        ? AppColors.glassDark.withValues(alpha: 0.5)
        : AppColors.white;
    final Color border = useDarkTiles
        ? AppColors.white.withValues(alpha: 0.14)
        : AppColors.white.withValues(alpha: 0.62);
    final Color fg =
        useDarkTiles ? AppColors.textOnDark : AppColors.primaryDark;

    return Semantics(
      button: true,
      label: context.l10n.mapSemanticResetRotationNorth,
      child: Material(
        color: AppColors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onReset,
          child: Container(
            width: _mapControlTapTargetSize,
            height: _mapControlTapTargetSize,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: Border.all(color: border),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: AnimatedRotation(
              turns: -rotationDegrees / 360,
              duration: AppMotion.fast,
              curve: Curves.easeOutCubic,
              child: Icon(Icons.navigation_rounded, size: 20, color: fg),
            ),
          ),
        ),
      ),
    );
  }
}
