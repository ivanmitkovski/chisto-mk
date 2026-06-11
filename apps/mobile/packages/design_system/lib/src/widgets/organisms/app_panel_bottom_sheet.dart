import 'dart:async';

import 'package:design_system/src/widgets/organisms/app_bottom_sheet/app_bottom_sheet.dart';
import 'package:flutter/material.dart';

/// How a scroll-controlled sheet reacts when the software keyboard opens.
enum SheetKeyboardInsetMode {
  /// Lifts the whole sheet above the keyboard (forms with pinned footers).
  lift,

  /// Keeps sheet height stable; keyboard overlays; child scrolls internally.
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
      ? MediaQuery.viewInsetsOf(context).bottom
      : 0;

  return Padding(
    padding: EdgeInsets.only(bottom: keyboardBottom),
    child: LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double heightCap = maxHeight ?? constraints.maxHeight;

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
