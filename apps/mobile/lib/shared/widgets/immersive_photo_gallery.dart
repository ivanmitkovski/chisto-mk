import 'dart:ui';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/shared/utils/app_haptics.dart';
import 'package:chisto_mobile/shared/widgets/app_smart_image.dart';
import 'package:flutter/material.dart';

class GalleryImageItem {
  const GalleryImageItem({
    required this.image,
    required this.heroTag,
    this.semanticLabel,
  });

  final ImageProvider image;
  final String heroTag;
  final String? semanticLabel;
}

typedef GalleryOverlayBuilder =
    Widget Function(BuildContext context, int currentIndex, int totalCount);

class ImmersivePhotoGallery extends StatefulWidget {
  const ImmersivePhotoGallery({
    super.key,
    required this.items,
    this.aspectRatio = 16 / 9,
    this.borderRadius = 20,
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
        barrierColor: Colors.transparent,
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
                    final double lift = (1 - curved.value) * 18;
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
                            Colors.black.withValues(alpha: 0.34),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.24),
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
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: -0.1,
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
      Colors.black,
      AppColors.primaryDark,
      0.16,
    )!.withValues(alpha: _backgroundOpacity);

    return Scaffold(
      backgroundColor: Colors.transparent,
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
                        return _ZoomableGalleryImage(
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
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                      letterSpacing: -0.2,
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
                                _GalleryThumbnailRail(
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
                              child: const Center(
                                child: GalleryGlassPill(
                                  child: Text(
                                    'Pinch or double-tap to zoom',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                      letterSpacing: -0.1,
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
                            Colors.black.withValues(
                              alpha: 0.28 * chromeOpacity,
                            ),
                            Colors.transparent,
                            Colors.black.withValues(
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
                      child: const Center(
                        child: Text(
                          'Drag down to close',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                            letterSpacing: -0.1,
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

class _ZoomableGalleryImage extends StatefulWidget {
  const _ZoomableGalleryImage({
    required this.item,
    required this.controller,
    required this.onDoubleTap,
  });

  final GalleryImageItem item;
  final TransformationController controller;
  final ValueChanged<TapDownDetails> onDoubleTap;

  @override
  State<_ZoomableGalleryImage> createState() => _ZoomableGalleryImageState();
}

class _ZoomableGalleryImageState extends State<_ZoomableGalleryImage> {
  TapDownDetails? _doubleTapDetails;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: (TapDownDetails details) {
        _doubleTapDetails = details;
      },
      onDoubleTap: () {
        final TapDownDetails? details = _doubleTapDetails;
        if (details == null) return;
        widget.onDoubleTap(details);
      },
      child: InteractiveViewer(
        transformationController: widget.controller,
        minScale: 1,
        maxScale: 4.5,
        panEnabled: true,
        scaleEnabled: true,
        clipBehavior: Clip.none,
        boundaryMargin: const EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: AppSmartImage(
            image: widget.item.image,
            fit: BoxFit.contain,
            semanticLabel: widget.item.semanticLabel,
          ),
        ),
      ),
    );
  }
}

class GalleryGlassPill extends StatelessWidget {
  const GalleryGlassPill({
    super.key,
    required this.child,
    this.padding,
    this.emphasis = GalleryGlassPillEmphasis.regular,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final GalleryGlassPillEmphasis emphasis;

  @override
  Widget build(BuildContext context) {
    final bool strong = emphasis == GalleryGlassPillEmphasis.strong;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: strong ? 16 : 12,
          sigmaY: strong ? 16 : 12,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: strong ? 0.3 : 0.22),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withValues(alpha: strong ? 0.16 : 0.1),
              width: 0.8,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: strong ? 14 : 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding:
                padding ??
                const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
            child: child,
          ),
        ),
      ),
    );
  }
}

enum GalleryGlassPillEmphasis { regular, strong }

class GalleryPageIndicators extends StatelessWidget {
  const GalleryPageIndicators({
    super.key,
    required this.currentIndex,
    required this.totalCount,
    this.activeColor = Colors.white,
    this.inactiveOpacity = 0.34,
    this.maxVisible = 5,
  });

  final int currentIndex;
  final int totalCount;
  final Color activeColor;
  final double inactiveOpacity;
  final int maxVisible;

  @override
  Widget build(BuildContext context) {
    final int visibleCount = totalCount <= maxVisible ? totalCount : maxVisible;
    final int halfWindow = visibleCount ~/ 2;
    int start = 0;
    if (totalCount > visibleCount) {
      start = currentIndex - halfWindow;
      if (start < 0) {
        start = 0;
      }
      if (start > totalCount - visibleCount) {
        start = totalCount - visibleCount;
      }
    }
    final int end = start + visibleCount;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(visibleCount, (int localIndex) {
        final int index = start + localIndex;
        final bool isActive = index == currentIndex;
        final bool isEdgeDot =
            totalCount > visibleCount && (index == start || index == end - 1);
        return AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.emphasized,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: isActive ? 18 : (isEdgeDot ? 4 : 6),
          height: 4,
          decoration: BoxDecoration(
            color: activeColor.withValues(
              alpha: isActive ? 0.96 : inactiveOpacity,
            ),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class GalleryGlassIconButton extends StatelessWidget {
  const GalleryGlassIconButton({super.key, required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.14),
              width: 0.8,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(icon, size: 22, color: Colors.white),
        ),
      ),
    );
  }
}

class _GalleryThumbnailRail extends StatelessWidget {
  const _GalleryThumbnailRail({
    required this.items,
    required this.currentIndex,
    required this.onSelect,
  });

  final List<GalleryImageItem> items;
  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.26),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 0.8,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Text(
                  'Photos',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                    letterSpacing: -0.1,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 52,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  separatorBuilder: (BuildContext context, int index) =>
                      const SizedBox(width: AppSpacing.xs),
                  itemBuilder: (BuildContext context, int index) {
                    final bool isActive = index == currentIndex;
                    return GestureDetector(
                      onTap: () => onSelect(index),
                      child: AnimatedContainer(
                        duration: AppMotion.fast,
                        curve: AppMotion.emphasized,
                        width: isActive ? 54 : 46,
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isActive
                                ? Colors.white.withValues(alpha: 0.9)
                                : Colors.white.withValues(alpha: 0.16),
                            width: isActive ? 1.4 : 0.9,
                          ),
                          boxShadow: isActive
                              ? <BoxShadow>[
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.18),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                ]
                              : const <BoxShadow>[],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(13),
                          child: AppSmartImage(image: items[index].image),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
