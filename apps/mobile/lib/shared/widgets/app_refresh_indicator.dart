import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';

/// Pull-to-refresh chrome shared with the home feed: primary stroke on a surface
/// plate ([ThemeData.scaffoldBackgroundColor]).
class AppRefreshIndicator extends StatelessWidget {
  const AppRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
    this.notificationPredicate,
    this.triggerMode,
  });

  final Future<void> Function() onRefresh;
  final Widget child;
  final ScrollNotificationPredicate? notificationPredicate;
  final RefreshIndicatorTriggerMode? triggerMode;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppColors.primary,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      strokeWidth: 2.5,
      displacement: 40,
      notificationPredicate:
          notificationPredicate ?? defaultScrollNotificationPredicate,
      triggerMode: triggerMode ?? RefreshIndicatorTriggerMode.onEdge,
      child: child,
    );
  }
}
