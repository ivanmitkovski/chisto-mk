import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';

/// Create-event pickers: draggable dismiss (swipe down), same scrim as other sheets.
Future<T?> showCreateEventModalBottomSheet<T>({
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
