import 'package:flutter/cupertino.dart';

/// Cupertino modal popup with consistent barrier dismissal (photo picker, category sheet, …).
Future<T?> showAppActionSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showCupertinoModalPopup<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: builder,
  );
}
