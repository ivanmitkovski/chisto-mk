import 'package:design_system/src/theme/app_colors.dart';
import 'package:design_system/src/theme/app_motion.dart';
import 'package:design_system/src/theme/app_spacing.dart';
import 'package:flutter/material.dart';

/// Wraps [child] so a scroll-controlled modal sizes to content up to [maxHeight].
Widget wrapScrollControlledBottomSheet({
  required BuildContext context,
  required Widget child,
  double? maxHeight,
}) {
  final double keyboardBottom = MediaQuery.viewInsetsOf(context).bottom;

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

Future<T?> showAppPanelBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool useSafeArea = true,
  bool useRootNavigator = true,
  double? maxHeightFactor,
  Color? backgroundColor,
  Color? barrierColor,
}) {
  final MediaQueryData mq = MediaQuery.of(context);
  final double? maxHeight = maxHeightFactor == null
      ? null
      : (mq.size.height - mq.padding.top) * maxHeightFactor;

  return showModalBottomSheet<T>(
    context: context,
    sheetAnimationStyle: const AnimationStyle(
      duration: AppMotion.standard,
      curve: AppMotion.smooth,
    ),
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
    useRootNavigator: useRootNavigator,
    backgroundColor: backgroundColor ?? AppColors.panelBackground,
    barrierColor: barrierColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusSheet),
      ),
    ),
    clipBehavior: Clip.antiAlias,
    elevation: 0,
    constraints: maxHeight == null
        ? null
        : BoxConstraints(maxHeight: maxHeight),
    builder: (BuildContext sheetContext) {
      return wrapScrollControlledBottomSheet(
        context: sheetContext,
        maxHeight: maxHeight,
        child: builder(sheetContext),
      );
    },
  );
}
