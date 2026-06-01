import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Presents a map overlay sheet that stays above the software keyboard.
///
/// Uses [showModalBottomSheet] [useSafeArea] so the sheet (and its rounded top)
/// starts below the notch/status bar. Shrinks the sheet body by
/// [MediaQuery.viewInsets] and fills the keyboard overlap zone with
/// [AppColors.panelBackground] so the map does not bleed through the keyboard's
/// rounded top corners.
Future<T?> showMapBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    useSafeArea: true,
    backgroundColor: AppColors.transparent,
    isScrollControlled: true,
    clipBehavior: Clip.antiAlias,
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
          final MediaQueryData mq = MediaQuery.of(context);
          final double keyboardBottom = mq.viewInsets.bottom;
          final double maxSheetHeight =
              constraints.maxHeight - AppSpacing.sm - keyboardBottom;

          return Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxSheetHeight),
                  child: builder(context),
                ),
                if (keyboardBottom > 0)
                  ColoredBox(
                    color: AppColors.panelBackground,
                    child: SizedBox(height: keyboardBottom),
                  ),
              ],
            ),
          );
        },
      );
    },
  );
}
