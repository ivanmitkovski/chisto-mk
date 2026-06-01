import 'package:design_system/design_system.dart';
import 'package:design_system/src/widgets/organisms/app_panel_bottom_sheet.dart';
import 'package:flutter/material.dart';

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
    // [ReportSheetScaffold] already includes a grabber row; enabling the
    // modal's built-in drag handle duplicates it on iOS/macOS.
    showDragHandle: false,
    builder: (BuildContext sheetContext) {
      return wrapScrollControlledBottomSheet(
        context: sheetContext,
        child: builder(sheetContext),
      );
    },
  );
}
