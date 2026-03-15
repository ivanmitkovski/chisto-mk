import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_typography.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_smart_image.dart';
import 'package:chisto_mobile/shared/widgets/photo_gallery/photo_gallery_widgets.dart';

export 'package:chisto_mobile/shared/widgets/photo_gallery/photo_gallery_widgets.dart';

typedef GalleryOverlayBuilder =
    Widget Function(BuildContext context, int currentIndex, int totalCount);

class ImmersivePhotoGallery extends StatefulWidget {
  const ImmersivePhotoGallery({
    super.key,
    required this.items,
    this.aspectRatio = 16 / 9,
    this.borderRadius = AppSpacing.radiusXl,
    this.selectedIndex,
    this.onPageChanged,
    this.topLeftBuilder,
    this.bottomCenterBuilder,
    this.openLabel = 'Open photo gallery',
    this.enableFullscreen = true,
  });

  final List<GalleryImageItem> items;
  final double aspectRatio;
  final double borderRadius;
  final int? selectedIndex;
  final ValueChanged<int>? onPageChanged;
  final GalleryOverlayBuilder? topLeftBuilder;
  final GalleryOverlayBuilder? bottomCenterBuilder;
  final String openLabel;
  final bool enableFullscreen;

  @override
  State<ImmersivePhotoGallery> createState() => _ImmersivePhotoGalleryState();
}

class _ImmersivePhotoGalleryState extends State<ImmersivePhotoGallery> {
  late final PageController _pageController;
  int _currentIndex = 0;
  bool _didPrefetchImages = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.items.isEmpty
        ? 0
        : widget.selectedIndex?.clamp(0, widget.items.length - 1) ?? 0;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrefetchImages) return;
    _didPrefetchImages = true;
    for (int i = 0; i < widget.items.length && i < 3; i++) {
      precacheImage(widget.items[i].image, context);
    }
  }

  @override
  void didUpdateWidget(covariant ImmersivePhotoGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items.isEmpty) {
      _currentIndex = 0;
      return;
    }
    if (widget.items != oldWidget.items) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || widget.items.isEmpty) return;
        final int safeIndex = _currentIndex.clamp(0, widget.items.length - 1);
        _prefetchAround(safeIndex, shouldPrefetchCurrent: true);
      });
    }
    final int targetIndex =
        widget.selectedIndex?.clamp(0, widget.items.length - 1) ??
        _currentIndex;
    if (targetIndex == _currentIndex) return;
    _currentIndex = targetIndex;
    _pageController.animateToPage(
      targetIndex,
      duration: AppMotion.medium,
      curve: AppMotion.emphasized,
    );
  }

  void _openFullscreen() {
    if (!widget.enableFullscreen || widget.items.isEmpty) return;
    AppHaptics.softTransition();
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: AppColors.transparent,
        pageBuilder:
            (
              BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
            ) {
              return FullscreenPhotoGalleryScreen(
                items: widget.items,
                initialIndex: _currentIndex,
              );
            },
        transitionsBuilder:
            (
              BuildContext context,
              Animation<double> animation,
              Animation<double> secondaryAnimation,
              Widget child,
            ) {
              final Animation<double> curved = CurvedAnimation(
                parent: animation,
                curve: AppMotion.emphasized,
                reverseCurve: Curves.easeOutCubic,
              );
              return FadeTransition(
                opacity: curved,
                child: AnimatedBuilder(
                  animation: curved,
                  child: child,
                  builder: (BuildContext context, Widget? child) {
                    final double lift = (1 - curved.value) * AppSpacing.radius18;
                    return Transform.translate(
                      offset: Offset(0, lift),
                      child: ScaleTransition(
                        scale: Tween<double>(
                          begin: 0.982,
                          end: 1,
                        ).animate(curved),
                        child: child,
                      ),
                    );
                  },
                ),
              );
            },
        transitionDuration: AppMotion.medium,
        reverseTransitionDuration: AppMotion.fast,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return const SizedBox.shrink();
    }

    final int totalCount = widget.items.length;

    return Semantics(
      image: true,
      label: '${widget.openLabel}. ${_currentIndex + 1} of $totalCount.',
      child: GestureDetector(
        onTap: _openFullscreen,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: AspectRatio(
            aspectRatio: widget.aspectRatio,
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                PageView.builder(
                  controller: _pageController,
                  itemCount: totalCount,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (int index) {
                    AppHaptics.light();
                    setState(() => _currentIndex = index);
                    widget.onPageChanged?.call(index);
                    _prefetchAround(index);
                  },
                  itemBuilder: (BuildContext context, int index) {
                    final GalleryImageItem item = widget.items[index];
                    return SizedBox.expand(
                      child: AppSmartImage(
                        image: item.image,
                        semanticLabel: item.semanticLabel,
                      ),
                    );
                  },
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[
                            AppColors.black.withValues(alpha: 0.34),
                            AppColors.transparent,
                            AppColors.black.withValues(alpha: 0.24),
                          ],
                          stops: const <double>[0, 0.42, 1],
                        ),
                      ),
                    ),
                  ),
                ),
                if (widget.topLeftBuilder != null)
                  Positioned(
                    top: AppSpacing.sm,
                    left: AppSpacing.sm,
                    child: widget.topLeftBuilder!(
                      context,
                      _currentIndex,
                      totalCount,
                    ),
                  ),
                if (totalCount > 1)
                  Positioned(
                    top: AppSpacing.sm,
                    right: AppSpacing.sm,
                    child: GalleryGlassPill(
                      child: Text(
                        '${_currentIndex + 1}/$totalCount',
                        style: AppTypography.badgeLabel.copyWith(
                          fontSize: 12,
                          color: AppColors.textOnDark,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: AppSpacing.sm,
                  right: AppSpacing.sm,
                  bottom: AppSpacing.sm,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (widget.bottomCenterBuilder != null)
                        widget.bottomCenterBuilder!(
                          context,
                          _currentIndex,
                          totalCount,
                        ),
                      if (widget.bottomCenterBuilder != null && totalCount > 1)
                        const SizedBox(height: AppSpacing.xs),
                      if (totalCount > 1)
                        GalleryPageIndicators(
                          currentIndex: _currentIndex,
                          totalCount: totalCount,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _prefetchAround(int index, {bool shouldPrefetchCurrent = false}) {
    if (shouldPrefetchCurrent && index >= 0 && index < widget.items.length) {
      precacheImage(widget.items[index].image, context);
    }
    final int previous = index - 1;
    final int next = index + 1;
    if (previous >= 0 && previous < widget.items.length) {
      precacheImage(widget.items[previous].image, context);
    }
    if (next >= 0 && next < widget.items.length) {
      precacheImage(widget.items[next].image, context);
    }
  }
}

class FullscreenPhotoGalleryScreen extends StatefulWidget {
  const FullscreenPhotoGalleryScreen({
    super.key,
    required this.items,
    required this.initialIndex,
  });

  final List<GalleryImageItem> items;
  final int initialIndex;

  @override
  State<FullscreenPhotoGalleryScreen> createState() =>
      _FullscreenPhotoGalleryScreenState();
}

class _FullscreenPhotoGalleryScreenState
    extends State<FullscreenPhotoGalleryScreen> {
  late final PageController _pageController;
  late final List<TransformationController> _zoomControllers;
  late int _currentIndex;
  double _verticalDrag = 0;
  double _backgroundOpacity = 1;
  bool _didPrefetchImages = false;
  bool _didCrossDismissThreshold = false;

  bool get _isCurrentImageZoomed =>
      _zoomControllers[_currentIndex].value.getMaxScaleOnAxis() > 1.01;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _zoomControllers = List<TransformationController>.generate(
      widget.items.length,
      (_) => TransformationController(),
    );
    for (final TransformationController controller in _zoomControllers) {
      controller.addListener(_handleZoomChanged);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final TransformationController controller in _zoomControllers) {
      controller
        ..removeListener(_handleZoomChanged)
        ..dispose();
    }
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didPrefetchImages) return;
    _didPrefetchImages = true;
    for (int i = 0; i < widget.items.length && i < 3; i++) {
      precacheImage(widget.items[i].image, context);
    }
  }

  void _handleZoomChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    if (_isCurrentImageZoomed) return;
    setState(() {
      final double nextDrag =
          _verticalDrag + (details.delta.dy * (_verticalDrag == 0 ? 1 : 0.7));
      _verticalDrag = nextDrag.clamp(-220, 220);
      final bool crossedDismissThreshold = _verticalDrag.abs() > 96;
      if (crossedDismissThreshold != _didCrossDismissThreshold) {
        _didCrossDismissThreshold = crossedDismissThreshold;
        AppHaptics.light();
      }
      _backgroundOpacity = (1 - (_verticalDrag.abs() / 360)).clamp(0.28, 1.0);
    });
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    if (_isCurrentImageZoomed) return;
    if (_verticalDrag.abs() > 110 ||
        (details.primaryVelocity != null &&
            details.primaryVelocity!.abs() > 700)) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _verticalDrag = 0;
      _backgroundOpacity = 1;
      _didCrossDismissThreshold = false;
    });
  }

  void _resetZoomIfNeeded(int index) {
    if (index < 0 || index >= _zoomControllers.length) return;
    _zoomControllers[index].value = Matrix4.identity();
  }

  void _toggleZoom(TapDownDetails details, int index) {
    final TransformationController controller = _zoomControllers[index];
    final bool isZoomed = controller.value.getMaxScaleOnAxis() > 1.01;
    if (isZoomed) {
      AppHaptics.light();
      controller.value = Matrix4.identity();
      return;
    }

    final Offset tapPosition = details.localPosition;
    const double scale = 2.8;
    AppHaptics.light();
    controller.value = Matrix4.identity()
      ..translateByDouble(
        -tapPosition.dx * (scale - 1),
        -tapPosition.dy * (scale - 1),
        0,
        1,
      )
      ..scaleByDouble(scale, scale, 1, 1);
  }

  @override
  Widget build(BuildContext context) {
    final double topInset = MediaQuery.of(context).padding.top;
    final double bottomInset = MediaQuery.of(context).padding.bottom;
    final double chromeOpacity = _isCurrentImageZoomed ? 0 : 1;
    final Color backgroundColor = Color.lerp(
      AppColors.black,
      AppColors.primaryDark,
      0.16,
    )!.withValues(alpha: _backgroundOpacity);

    return Scaffold(
      backgroundColor: AppColors.transparent,
      body: GestureDetector(
        onVerticalDragUpdate: _handleVerticalDragUpdate,
        onVerticalDragEnd: _handleVerticalDragEnd,
        child: AnimatedContainer(
          duration: _verticalDrag == 0 ? AppMotion.medium : Duration.zero,
          curve: AppMotion.emphasized,
          color: backgroundColor,
          child: SafeArea(
            child: Stack(
              children: <Widget>[
                Center(
                  child: Transform.translate(
                    offset: Offset(0, _verticalDrag),
                    child: PageView.builder(
                      controller: _pageController,
                      physics: _isCurrentImageZoomed
                          ? const NeverScrollableScrollPhysics()
                          : const BouncingScrollPhysics(),
                      itemCount: widget.items.length,
                      onPageChanged: (int index) {
                        _resetZoomIfNeeded(_currentIndex);
                        AppHaptics.tap();
                        setState(() => _currentIndex = index);
                        _prefetchAround(index);
                      },
                      itemBuilder: (BuildContext context, int index) {
                        final GalleryImageItem item = widget.items[index];
                        return ZoomableGalleryImage(
                          item: item,
                          controller: _zoomControllers[index],
                          onDoubleTap: (TapDownDetails details) =>
                              _toggleZoom(details, index),
                        );
                      },
                    ),
                  ),
                ),
                AnimatedOpacity(
                  opacity: chromeOpacity,
                  duration: AppMotion.fast,
                  child: IgnorePointer(
                    ignoring: chromeOpacity == 0,
                    child: Stack(
                      children: <Widget>[
                        Positioned(
                          top: AppSpacing.sm,
                          left: AppSpacing.md,
                          child: Semantics(
                            button: true,
                            label: 'Close full-screen gallery',
                            child: GestureDetector(
                              onTap: () {
                                AppHaptics.tap();
                                Navigator.of(context).pop();
                              },
                              behavior: HitTestBehavior.opaque,
                              child: const GalleryGlassIconButton(
                                icon: Icons.close_rounded,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: AppSpacing.sm,
                          right: AppSpacing.md,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              if (widget.items.length > 1)
                                GalleryGlassPill(
                                  emphasis: GalleryGlassPillEmphasis.strong,
                                  child: Text(
                                    '${_currentIndex + 1} / ${widget.items.length}',
                                    style: AppTypography.chipLabel.copyWith(
                                      fontSize: 14,
                                      color: AppColors.textOnDark,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (widget.items.length > 1)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: bottomInset + AppSpacing.lg,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                GalleryThumbnailRail(
                                  items: widget.items,
                                  currentIndex: _currentIndex,
                                  onSelect: (int index) {
                                    if (index == _currentIndex) return;
                                    _resetZoomIfNeeded(_currentIndex);
                                    _pageController.animateToPage(
                                      index,
                                      duration: AppMotion.medium,
                                      curve: AppMotion.emphasized,
                                    );
                                  },
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                GalleryPageIndicators(
                                  currentIndex: _currentIndex,
                                  totalCount: widget.items.length,
                                ),
                              ],
                            ),
                          ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: widget.items.length > 1
                              ? bottomInset + 96
                              : bottomInset + AppSpacing.xl,
                          child: AnimatedOpacity(
                            opacity: chromeOpacity,
                            duration: AppMotion.fast,
                            child: IgnorePointer(
                              ignoring: chromeOpacity == 0,
                              child: Center(
                                child: GalleryGlassPill(
                                  child: Text(
                                    'Pinch or double-tap to zoom',
                                    style: AppTypography.badgeLabel.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textOnDark,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[
                            AppColors.black.withValues(
                              alpha: 0.28 * chromeOpacity,
                            ),
                            AppColors.transparent,
                            AppColors.black.withValues(
                              alpha: 0.24 * chromeOpacity,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: topInset + 52,
                  child: AnimatedOpacity(
                    opacity: chromeOpacity,
                    duration: AppMotion.fast,
                    child: IgnorePointer(
                      ignoring: chromeOpacity == 0,
                      child: Center(
                        child: Text(
                          'Drag down to close',
                          style: AppTypography.badgeLabel.copyWith(
                            fontWeight: FontWeight.w500,
                            color: AppColors.textOnDarkMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _prefetchAround(int index) {
    final int previous = index - 1;
    final int next = index + 1;
    if (previous >= 0 && previous < widget.items.length) {
      precacheImage(widget.items[previous].image, context);
    }
    if (next >= 0 && next < widget.items.length) {
      precacheImage(widget.items[next].image, context);
    }
  }
}
