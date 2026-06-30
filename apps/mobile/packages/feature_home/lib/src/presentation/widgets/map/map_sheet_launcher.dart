import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Presents a map overlay sheet that stays above the software keyboard.
///
/// Top spacing matches the resizable comments sheet host: reads the platform
/// notch inset via [appSheetViewportTopInset] because modal routes strip top
/// padding from descendant [MediaQuery]s.
///
/// Shrinks the scrollable body when the keyboard is open via in-sheet padding
/// (see map search modal). The host runs in [SheetKeyboardInsetMode.overlay] so
/// the sheet stays anchored to the screen bottom and the keyboard overlays it.
///
/// Do not also shrink this host by [MediaQuery.viewInsets] or append a keyboard
/// filler — that double-counts the inset and leaves a white band above the IME.
Future<T?> showMapBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return AppBottomSheet.show<T>(
    context: context,
    backgroundColor: AppColors.transparent,
    keyboardInsetMode: SheetKeyboardInsetMode.overlay,
    sheetAnimationStyle: const AnimationStyle(
      duration: AppMotion.standard,
      curve: AppMotion.smooth,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusSheet),
      ),
    ),
    builder: (BuildContext sheetContext) {
      return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double topInset = appSheetViewportTopInset(sheetContext);
          final double maxSheetHeight =
              (constraints.maxHeight - topInset - AppSpacing.sm).clamp(
                0.0,
                constraints.maxHeight,
              );

          return Padding(
            padding: EdgeInsets.only(top: topInset + AppSpacing.sm),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxSheetHeight),
              child: builder(context),
            ),
          );
        },
      );
    },
  );
}
