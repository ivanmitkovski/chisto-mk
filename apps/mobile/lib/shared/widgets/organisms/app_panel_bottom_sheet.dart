import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';

Future<T?> showAppPanelBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool useSafeArea = true,
  bool useRootNavigator = true,
  double? maxHeightFactor,
}) {
  final MediaQueryData mq = MediaQuery.of(context);
  final double? maxHeight = maxHeightFactor == null
      ? null
      : (mq.size.height - mq.padding.top) * maxHeightFactor;

  return showModalBottomSheet<T>(
    context: context,
    sheetAnimationStyle: AnimationStyle(
      duration: AppMotion.standard,
      curve: AppMotion.smooth,
    ),
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
    useRootNavigator: useRootNavigator,
    backgroundColor: AppColors.panelBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusSheet),
      ),
    ),
    clipBehavior: Clip.antiAlias,
    elevation: 0,
    constraints: maxHeight == null ? null : BoxConstraints(maxHeight: maxHeight),
    builder: builder,
  );
}

