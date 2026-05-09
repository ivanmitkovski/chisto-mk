import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';

Future<T?> showMapBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  final MediaQueryData mq = MediaQuery.of(context);
  final double maxHeight =
      mq.size.height - mq.padding.top - AppSpacing.sm;

  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    backgroundColor: AppColors.transparent,
    isScrollControlled: true,
    constraints: BoxConstraints(maxHeight: maxHeight),
    builder: builder,
  );
}
