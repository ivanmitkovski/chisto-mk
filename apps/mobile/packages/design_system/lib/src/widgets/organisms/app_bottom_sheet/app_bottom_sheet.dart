import 'dart:async';

import 'package:design_system/src/theme/app_colors.dart';
import 'package:design_system/src/theme/app_motion.dart';
import 'package:design_system/src/theme/app_spacing.dart';
import 'package:design_system/src/widgets/organisms/app_bottom_sheet/app_resizable_sheet.dart';
import 'package:design_system/src/widgets/organisms/app_bottom_sheet/app_resizable_sheet_scrim_tap.dart';
import 'package:design_system/src/widgets/organisms/app_bottom_sheet/app_sheet_drag.dart';
import 'package:design_system/src/widgets/organisms/app_panel_bottom_sheet.dart';
import 'package:flutter/material.dart';

export 'app_resizable_sheet.dart';
export 'app_resizable_sheet_drag_surface.dart';
export 'app_resizable_sheet_scrim_tap.dart';
export 'app_sheet_drag.dart';

/// Standard bottom sheet presentation for the mobile app.
///
/// - [show] — content-height sheets with native modal drag-to-dismiss.
/// - [showResizable] — snap-detent sheets with header drag + overscroll dismiss.
abstract final class AppBottomSheet {
  /// Height cap for [maxHeightFactor] accounting for modal [useSafeArea].
  ///
  /// Reads top inset from the platform [View] because modal routes strip top
  /// padding from descendant [MediaQuery]s.
  static double _maxSheetHeight(
    BuildContext context,
    double maxHeightFactor,
    bool useSafeArea,
  ) {
    final MediaQueryData viewData = MediaQueryData.fromView(View.of(context));
    final double topInset = viewData.viewPadding.top;
    final double bottomInset = useSafeArea ? viewData.viewPadding.bottom : 0;
    return (viewData.size.height - topInset - bottomInset) * maxHeightFactor;
  }

  /// Bottom scroll padding clearing the home indicator in edge-to-edge sheets.
  static double homeIndicatorScrollPadding(
    BuildContext context, {
    double extra = AppSpacing.sm,
  }) {
    return MediaQuery.viewPaddingOf(context).bottom + extra;
  }

  /// Content-height / fixed-max modal bottom sheet.
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool isScrollControlled = true,
    bool useSafeArea = false,
    bool useRootNavigator = true,
    double? maxHeightFactor,
    Color? backgroundColor,
    Color? barrierColor,
    SheetKeyboardInsetMode keyboardInsetMode = SheetKeyboardInsetMode.lift,
    bool dismissible = true,
    FutureOr<bool> Function()? canDismiss,
    String? barrierLabel,
    bool showDragHandle = false,
    ShapeBorder? shape,
    AnimationStyle? sheetAnimationStyle,
    Clip clipBehavior = Clip.antiAlias,
  }) {
    final double? maxHeight = maxHeightFactor == null
        ? null
        : _maxSheetHeight(context, maxHeightFactor, useSafeArea);

    return showModalBottomSheet<T>(
      context: context,
      sheetAnimationStyle:
          sheetAnimationStyle ??
          const AnimationStyle(
            duration: AppMotion.standard,
            curve: AppMotion.smooth,
          ),
      isScrollControlled: isScrollControlled,
      useSafeArea: useSafeArea,
      useRootNavigator: useRootNavigator,
      isDismissible: dismissible,
      enableDrag: dismissible,
      showDragHandle: showDragHandle,
      backgroundColor: backgroundColor ?? AppColors.panelBackground,
      barrierColor: barrierColor ?? AppColors.overlay,
      barrierLabel: barrierLabel,
      shape:
          shape ??
          const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppSpacing.radiusSheet),
            ),
          ),
      clipBehavior: clipBehavior,
      elevation: 0,
      constraints: maxHeight == null
          ? null
          : BoxConstraints(maxHeight: maxHeight),
      builder: (BuildContext sheetContext) {
        Widget body = builder(sheetContext);

        if (canDismiss != null) {
          body = _AppBottomSheetDismissGuard(
            canDismiss: canDismiss,
            child: body,
          );
        }

        Widget sheet = wrapScrollControlledBottomSheet(
          context: sheetContext,
          maxHeight: maxHeight,
          keyboardInsetMode: keyboardInsetMode,
          child: _ModalSheetViewportMediaQuery(child: body),
        );

        if (keyboardInsetMode == SheetKeyboardInsetMode.overlay) {
          sheet = MediaQuery.removeViewInsets(
            context: sheetContext,
            removeBottom: true,
            child: sheet,
          );
        }

        return sheet;
      },
    );
  }

  /// Snap-detent resizable modal bottom sheet.
  static Future<T?> showResizable<T>({
    required BuildContext context,
    required AppSheetSizeConfig sizeConfig,
    required Widget Function(
      BuildContext sheetContext,
      ScrollController scrollController,
      DraggableScrollableController sheetController,
      AppSheetSizeConfig sizeConfig,
    )
    builder,
    bool useRootNavigator = true,
    bool useSafeArea = false,
    Color? barrierColor,
    Color? backgroundColor,
    String? barrierLabel,
    String? dragHandleSemanticLabel,
    FutureOr<bool> Function()? canDismiss,
    DraggableScrollableController? sheetController,
    ValueChanged<AppSheetSizeConfig>? onSizeConfigChanged,
  }) {
    final DraggableScrollableController controller =
        sheetController ?? DraggableScrollableController();

    return showModalBottomSheet<T>(
      context: context,
      useRootNavigator: useRootNavigator,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: false,
      useSafeArea: useSafeArea,
      barrierColor: barrierColor ?? AppColors.overlay,
      barrierLabel: barrierLabel,
      backgroundColor: backgroundColor ?? AppColors.transparent,
      builder: (BuildContext sheetContext) {
        Widget sheet = _AppResizableBottomSheetHost(
          sizeConfig: sizeConfig,
          sheetController: controller,
          dragHandleSemanticLabel: dragHandleSemanticLabel,
          onSizeConfigChanged: onSizeConfigChanged,
          onScrimTap: () => _handleResizableScrimTap(sheetContext, canDismiss),
          builder: builder,
        );

        if (canDismiss != null) {
          sheet = _AppBottomSheetDismissGuard(
            canDismiss: canDismiss,
            child: sheet,
          );
        }

        return sheet;
      },
    );
  }
}

/// Merges live platform [View] insets into the sheet [MediaQuery].
///
/// Modal routes strip top padding from descendant [MediaQuery]s. This re-exposes
/// notch [viewPadding] and keyboard [viewInsets] from the platform [View] for
/// layout and scroll padding. Overlay hosts additionally strip bottom
/// [viewInsets] via [MediaQuery.removeViewInsets] after this wrapper.
///
/// Intentionally stateless: rely on [showModalBottomSheet] route rebuilds on
/// metrics changes. A [WidgetsBindingObserver] here forced full-tree [setState]
/// during IME animation and dropped text-field focus on iOS.
class _ModalSheetViewportMediaQuery extends StatelessWidget {
  const _ModalSheetViewportMediaQuery({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData routeMq = MediaQuery.of(context);
    final MediaQueryData viewMq = MediaQueryData.fromView(View.of(context));
    return MediaQuery(
      data: routeMq.copyWith(
        viewInsets: viewMq.viewInsets,
        viewPadding: viewMq.viewPadding,
        padding: routeMq.padding.copyWith(top: viewMq.viewPadding.top),
      ),
      child: child,
    );
  }
}

Future<void> _handleResizableScrimTap(
  BuildContext context,
  FutureOr<bool> Function()? canDismiss,
) async {
  if (canDismiss != null) {
    final bool allowed = await Future<bool>.value(canDismiss());
    if (!allowed || !context.mounted) {
      return;
    }
  }
  unawaited(Navigator.of(context).maybePop());
}

/// Host for resizable sheets: notch top padding, keyboard overlay model.
class _AppResizableBottomSheetHost extends StatefulWidget {
  const _AppResizableBottomSheetHost({
    required this.sizeConfig,
    required this.sheetController,
    required this.builder,
    required this.onScrimTap,
    this.dragHandleSemanticLabel,
    this.onSizeConfigChanged,
  });

  final AppSheetSizeConfig sizeConfig;
  final DraggableScrollableController sheetController;
  final VoidCallback onScrimTap;
  final String? dragHandleSemanticLabel;
  final ValueChanged<AppSheetSizeConfig>? onSizeConfigChanged;
  final Widget Function(
    BuildContext sheetContext,
    ScrollController scrollController,
    DraggableScrollableController sheetController,
    AppSheetSizeConfig sizeConfig,
  )
  builder;

  @override
  State<_AppResizableBottomSheetHost> createState() =>
      _AppResizableBottomSheetHostState();
}

class _AppResizableBottomSheetHostState
    extends State<_AppResizableBottomSheetHost> {
  bool _didExpandForKeyboard = false;

  @override
  Widget build(BuildContext context) {
    final MediaQueryData viewData = MediaQueryData.fromView(View.of(context));
    final AppSheetSizeConfig activeConfig = appSheetSizeConfigForViewport(
      widget.sizeConfig,
      viewData,
    );
    final double topInset = viewData.viewPadding.top;
    final double keyboardInset = viewData.viewInsets.bottom;
    final bool keyboardOpen = keyboardInset > 0;

    if (!keyboardOpen && _didExpandForKeyboard) {
      _didExpandForKeyboard = false;
    }

    widget.onSizeConfigChanged?.call(activeConfig);

    if (keyboardOpen && !_didExpandForKeyboard) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        if (!widget.sheetController.isAttached) {
          return;
        }
        if (widget.sheetController.size >= activeConfig.maxSize - 0.01) {
          _didExpandForKeyboard = true;
          return;
        }
        _didExpandForKeyboard = true;
        widget.sheetController.animateTo(
          activeConfig.maxSize,
          duration: AppMotion.medium,
          curve: AppMotion.emphasized,
        );
      });
    }

    return MediaQuery.removeViewInsets(
      context: context,
      removeBottom: true,
      child: AppResizableSheetScrimTap(
        sheetController: widget.sheetController,
        topInset: topInset,
        initialExtent: activeConfig.resolvedInitialSize,
        onTap: widget.onScrimTap,
        child: Padding(
          padding: EdgeInsets.only(top: topInset),
          child: DraggableScrollableSheet(
            controller: widget.sheetController,
            expand: false,
            initialChildSize: activeConfig.resolvedInitialSize,
            minChildSize: activeConfig.minSize,
            maxChildSize: activeConfig.maxSize,
            snap: activeConfig.snapSizes.isNotEmpty,
            snapSizes: activeConfig.snapSizes.isEmpty
                ? null
                : activeConfig.snapSizes,
            builder:
                (BuildContext sheetContext, ScrollController scrollController) {
                  return AppResizableSheet(
                    sizeConfig: activeConfig,
                    sheetController: widget.sheetController,
                    scrollController: scrollController,
                    dragHandleSemanticLabel: widget.dragHandleSemanticLabel,
                    builder: widget.builder,
                  );
                },
          ),
        ),
      ),
    );
  }
}

class _AppBottomSheetDismissGuard extends StatefulWidget {
  const _AppBottomSheetDismissGuard({
    required this.canDismiss,
    required this.child,
  });

  final FutureOr<bool> Function() canDismiss;
  final Widget child;

  @override
  State<_AppBottomSheetDismissGuard> createState() =>
      _AppBottomSheetDismissGuardState();
}

class _AppBottomSheetDismissGuardState
    extends State<_AppBottomSheetDismissGuard> {
  void _onPopInvoked(bool didPop, Object? result) {
    if (didPop) {
      return;
    }
    unawaited(_handlePop(result));
  }

  Future<void> _handlePop(Object? result) async {
    final bool allowed = await Future<bool>.value(widget.canDismiss());
    if (allowed && mounted) {
      Navigator.of(context).pop(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onPopInvoked,
      child: widget.child,
    );
  }
}
