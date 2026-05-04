import 'package:flutter/material.dart';

/// Full-screen navigation for reports while the user is inside [HomeShell].
class ReportsNavigation {
  const ReportsNavigation._();

  /// [HomeShell] nests a [GoRouter] navigator. Pushing on that stack keeps the
  /// shell scaffold (bottom bar + central FAB) visible. The multi-step report
  /// flow must use [MaterialApp]'s root navigator instead.
  static NavigatorState _rootNavigator(BuildContext context) {
    return Navigator.of(context, rootNavigator: true);
  }

  static Future<T?> pushNewReportScreen<T extends Object?>(
    BuildContext context, {
    required Widget child,
  }) {
    return _rootNavigator(
      context,
    ).push<T>(MaterialPageRoute<T>(builder: (_) => child));
  }
}
