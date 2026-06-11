import 'dart:async';

import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// @deprecated Use [AppBottomSheet.show] instead.
@Deprecated('Use AppBottomSheet.show instead.')
Future<T?> showEventsSurfaceModal<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  SheetKeyboardInsetMode keyboardInsetMode = SheetKeyboardInsetMode.lift,
  bool dismissible = true,
  FutureOr<bool> Function()? canDismiss,
}) {
  return AppBottomSheet.show<T>(
    context: context,
    backgroundColor: AppColors.transparent,
    keyboardInsetMode: keyboardInsetMode,
    dismissible: dismissible,
    canDismiss: canDismiss,
    builder: builder,
  );
}
