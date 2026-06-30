import 'dart:async';
import 'dart:math' as math;

import 'package:design_system/src/widgets/organisms/app_bottom_sheet/app_bottom_sheet.dart';
import 'package:flutter/material.dart';

/// How a scroll-controlled sheet reacts when the software keyboard opens.
enum SheetKeyboardInsetMode {
  /// Lifts the whole sheet above the keyboard via bottom padding on the modal
  /// host. Use for form sheets with text fields and pinned footers.
  lift,

  /// Keeps sheet height stable; keyboard overlays; child scrolls internally.
  /// Use for map/search sheets that need a fixed height cap — not form sheets.
  overlay,
}

/// Wraps [child] so a scroll-controlled modal sizes to content up to [maxHeight].
Widget wrapScrollControlledBottomSheet({
  required BuildContext context,
  required Widget child,
  double? maxHeight,
  SheetKeyboardInsetMode keyboardInsetMode = SheetKeyboardInsetMode.lift,
}) {
  final double keyboardBottom = keyboardInsetMode == SheetKeyboardInsetMode.lift
      ? MediaQueryData.fromView(View.of(context)).viewInsets.bottom
      : 0;

  return Padding(
    padding: EdgeInsets.only(bottom: keyboardBottom),
    child: LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double heightCap = maxHeight == null
            ? constraints.maxHeight
            : math.min(maxHeight, constraints.maxHeight);

        // Content-hugging sheets must size to the child; lift padding sits in the
        // transparent band below the painted panel (not inside the sheet chrome).
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: heightCap),
              child: child,
            ),
          ],
        );
      },
    ),
  );
}

/// @deprecated Use [AppBottomSheet.show] instead.
@Deprecated('Use AppBottomSheet.show instead.')
Future<T?> showAppPanelBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool useSafeArea = true,
  bool useRootNavigator = true,
  double? maxHeightFactor,
  Color? backgroundColor,
  Color? barrierColor,
  SheetKeyboardInsetMode keyboardInsetMode = SheetKeyboardInsetMode.lift,
  bool dismissible = true,
  FutureOr<bool> Function()? canDismiss,
  String? barrierLabel,
}) {
  return AppBottomSheet.show<T>(
    context: context,
    builder: builder,
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
    useRootNavigator: useRootNavigator,
    maxHeightFactor: maxHeightFactor,
    backgroundColor: backgroundColor,
    barrierColor: barrierColor,
    keyboardInsetMode: keyboardInsetMode,
    dismissible: dismissible,
    canDismiss: canDismiss,
    barrierLabel: barrierLabel,
  );
}
