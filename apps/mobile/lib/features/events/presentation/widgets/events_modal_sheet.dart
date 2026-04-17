import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';

/// Event vertical bottom sheets: draggable dismiss, root navigator, shared scrim.
///
/// Use for create/edit pickers, help sheets, and event detail modals so nested
/// navigators behave consistently.
Future<T?> showEventsSurfaceModal<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: AppColors.transparent,
    barrierColor: AppColors.overlay,
    isDismissible: true,
    enableDrag: true,
    showDragHandle: false,
    builder: builder,
  );
}
