import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Scrollable auth form body with keyboard inset padding for [AuthShell].
class AuthFormScaffold extends StatelessWidget {
  const AuthFormScaffold({
    super.key,
    required this.child,
    this.padding,
    this.scrollController,
    this.physics,
  });

  final Widget child;
  final EdgeInsets? padding;
  final ScrollController? scrollController;
  final ScrollPhysics? physics;

  @override
  Widget build(BuildContext context) {
    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    return SingleChildScrollView(
      controller: scrollController,
      physics: physics,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding:
          padding ??
          EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg + keyboardInset,
          ),
      child: child,
    );
  }
}
