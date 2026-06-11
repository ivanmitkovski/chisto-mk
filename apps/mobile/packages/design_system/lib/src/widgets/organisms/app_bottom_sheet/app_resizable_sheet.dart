import 'package:design_system/src/theme/app_colors.dart';
import 'package:design_system/src/theme/app_motion.dart';
import 'package:design_system/src/theme/app_spacing.dart';
import 'package:design_system/src/widgets/organisms/app_bottom_sheet/app_resizable_sheet_drag_surface.dart';
import 'package:design_system/src/widgets/organisms/app_bottom_sheet/app_sheet_drag.dart';
import 'package:flutter/material.dart';

/// Header drag zone for resizable sheets: grabber + optional custom chrome.
class AppResizableSheetHeader extends StatelessWidget {
  const AppResizableSheetHeader({
    super.key,
    required this.sheetController,
    required this.sizeConfig,
    this.semanticLabel,
    this.child,
  });

  final DraggableScrollableController sheetController;
  final AppSheetSizeConfig sizeConfig;
  final String? semanticLabel;
  final Widget? child;

  void _onVerticalDragStart(DragStartDetails details) {}

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!sheetController.isAttached) {
      return;
    }
    final double? primaryDelta = details.primaryDelta;
    if (primaryDelta == null) {
      return;
    }
    final double deltaSize = sheetController.pixelsToSize(primaryDelta);
    final double nextSize = appSheetSizeAfterDrag(
      size: sheetController.size,
      deltaSize: deltaSize,
      minSize: sizeConfig.minSize,
      maxSize: sizeConfig.maxSize,
    );
    sheetController.jumpTo(nextSize);
  }

  void _onVerticalDragEnd(BuildContext context, DragEndDetails details) {
    if (!sheetController.isAttached) {
      return;
    }
    final AppSheetDragEndResult result = resolveAppSheetDragEnd(
      size: sheetController.size,
      velocity: details.primaryVelocity,
      minSize: sizeConfig.minSize,
      maxSize: sizeConfig.maxSize,
      snapSizes: sizeConfig.snapSizes,
    );
    switch (result.action) {
      case AppSheetDragEndAction.animateTo:
        sheetController.animateTo(
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
    final Widget grabber = Semantics(
      button: true,
      label: semanticLabel,
      child: Container(
        width: AppSpacing.sheetHandle,
        height: AppSpacing.sheetHandleHeight,
        decoration: BoxDecoration(
          color: AppColors.divider,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
        ),
      ),
    );

    final Widget content = child ??
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Center(child: grabber),
        );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: _onVerticalDragStart,
      onVerticalDragUpdate: _onVerticalDragUpdate,
      onVerticalDragEnd: (DragEndDetails details) =>
          _onVerticalDragEnd(context, details),
      child: content,
    );
  }
}

/// Wraps scroll content with overscroll-at-top dismiss for resizable sheets.
class AppResizableSheetScrollBody extends StatelessWidget {
  const AppResizableSheetScrollBody({
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

  bool _scrollAtTop() {
    if (!scrollController.hasClients) {
      return true;
    }
    return scrollController.position.pixels <= scrollController.position.minScrollExtent + 0.5;
  }

  bool _handleOverscrollDismiss(
    BuildContext context,
    OverscrollNotification notification,
  ) {
    if (notification.overscroll <= 0 || !_scrollAtTop()) {
      return false;
    }
    if (!sheetController.isAttached) {
      return false;
    }
    final double deltaSize = sheetController.pixelsToSize(notification.overscroll);
    final double nextSize = appSheetSizeAfterDrag(
      size: sheetController.size,
      deltaSize: deltaSize,
      minSize: sizeConfig.minSize,
      maxSize: sizeConfig.maxSize,
    );
    if (nextSize <= sizeConfig.minSize + kAppSheetDismissSlop) {
      Navigator.of(context).maybePop();
      return true;
    }
    sheetController.jumpTo(nextSize);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<OverscrollNotification>(
      onNotification: (OverscrollNotification notification) =>
          _handleOverscrollDismiss(context, notification),
      child: child,
    );
  }
}

/// Resizable bottom sheet body hosted inside [AppBottomSheet.showResizable].
class AppResizableSheet extends StatelessWidget {
  const AppResizableSheet({
    super.key,
    required this.sizeConfig,
    required this.sheetController,
    required this.scrollController,
    required this.builder,
    this.borderRadius = const BorderRadius.vertical(
      top: Radius.circular(AppSpacing.radiusPill),
    ),
    this.backgroundColor = AppColors.panelBackground,
    this.dragHandleSemanticLabel,
  });

  final AppSheetSizeConfig sizeConfig;
  final DraggableScrollableController sheetController;
  final ScrollController scrollController;
  final Widget Function(
    BuildContext context,
    ScrollController scrollController,
    DraggableScrollableController sheetController,
    AppSheetSizeConfig sizeConfig,
  ) builder;
  final BorderRadius borderRadius;
  final Color backgroundColor;
  final String? dragHandleSemanticLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: borderRadius,
      ),
      clipBehavior: Clip.antiAlias,
      child: AppResizableSheetScrollBody(
        scrollController: scrollController,
        sheetController: sheetController,
        sizeConfig: sizeConfig,
        child: AppResizableSheetDragSurface(
          scrollController: scrollController,
          sheetController: sheetController,
          sizeConfig: sizeConfig,
          child: builder(
            context,
            scrollController,
            sheetController,
            sizeConfig,
          ),
        ),
      ),
    );
  }
}
