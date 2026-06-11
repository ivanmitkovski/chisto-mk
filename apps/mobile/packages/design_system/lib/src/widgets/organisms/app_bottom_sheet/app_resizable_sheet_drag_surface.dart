import 'package:design_system/src/theme/app_motion.dart';
import 'package:design_system/src/widgets/organisms/app_bottom_sheet/app_sheet_drag.dart';
import 'package:flutter/material.dart';

/// Body-level vertical drag for resizable sheets when the scroll view is at top.
///
/// Complements [AppResizableSheetHeader] and overscroll dismiss so users can
/// resize/dismiss from empty or header-adjacent areas (Instagram-style).
class AppResizableSheetDragSurface extends StatefulWidget {
  const AppResizableSheetDragSurface({
    super.key,
    required this.scrollController,
    required this.sheetController,
    required this.sizeConfig,
    required this.child,
  });

  final ScrollController scrollController;
  final DraggableScrollableController sheetController;
  final AppSheetSizeConfig sizeConfig;
  final Widget child;

  @override
  State<AppResizableSheetDragSurface> createState() =>
      _AppResizableSheetDragSurfaceState();
}

class _AppResizableSheetDragSurfaceState
    extends State<AppResizableSheetDragSurface> {
  bool _scrollAtTop = true;
  bool _unfocusedForDrag = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_syncScrollAtTop);
    _syncScrollAtTop();
  }

  @override
  void didUpdateWidget(covariant AppResizableSheetDragSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController.removeListener(_syncScrollAtTop);
      widget.scrollController.addListener(_syncScrollAtTop);
      _syncScrollAtTop();
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_syncScrollAtTop);
    super.dispose();
  }

  void _syncScrollAtTop() {
    final bool atTop = _isScrollAtTop();
    if (atTop != _scrollAtTop && mounted) {
      setState(() => _scrollAtTop = atTop);
    }
  }

  bool _isScrollAtTop() {
    if (!widget.scrollController.hasClients) {
      return true;
    }
    return widget.scrollController.position.pixels <=
        widget.scrollController.position.minScrollExtent + 0.5;
  }

  bool get _canDragSheet =>
      _scrollAtTop && widget.sheetController.isAttached;

  void _onVerticalDragStart(DragStartDetails details) {
    _unfocusedForDrag = false;
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (!_canDragSheet) {
      return;
    }
    if (!_unfocusedForDrag) {
      FocusManager.instance.primaryFocus?.unfocus();
      _unfocusedForDrag = true;
    }
    final double? primaryDelta = details.primaryDelta;
    if (primaryDelta == null) {
      return;
    }
    final double deltaSize = widget.sheetController.pixelsToSize(primaryDelta);
    final double nextSize = appSheetSizeAfterDrag(
      size: widget.sheetController.size,
      deltaSize: deltaSize,
      minSize: widget.sizeConfig.minSize,
      maxSize: widget.sizeConfig.maxSize,
    );
    widget.sheetController.jumpTo(nextSize);
  }

  void _onVerticalDragEnd(BuildContext context, DragEndDetails details) {
    _unfocusedForDrag = false;
    if (!_canDragSheet) {
      return;
    }
    final AppSheetDragEndResult result = resolveAppSheetDragEnd(
      size: widget.sheetController.size,
      velocity: details.primaryVelocity,
      minSize: widget.sizeConfig.minSize,
      maxSize: widget.sizeConfig.maxSize,
      snapSizes: widget.sizeConfig.snapSizes,
    );
    switch (result.action) {
      case AppSheetDragEndAction.animateTo:
        widget.sheetController.animateTo(
          result.targetSize!,
          duration: AppMotion.medium,
          curve: AppMotion.emphasized,
        );
      case AppSheetDragEndAction.dismiss:
        Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification is ScrollUpdateNotification ||
            notification is ScrollEndNotification) {
          _syncScrollAtTop();
        }
        return false;
      },
      child: GestureDetector(
        behavior: HitTestBehavior.deferToChild,
        onVerticalDragStart: _canDragSheet ? _onVerticalDragStart : null,
        onVerticalDragUpdate: _canDragSheet ? _onVerticalDragUpdate : null,
        onVerticalDragEnd: _canDragSheet
            ? (DragEndDetails details) => _onVerticalDragEnd(context, details)
            : null,
        child: widget.child,
      ),
    );
  }
}
