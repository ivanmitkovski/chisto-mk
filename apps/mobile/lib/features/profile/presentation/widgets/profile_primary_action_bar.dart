import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';

/// Bottom bar for profile form screens: same insets as sibling flows.
///
/// When the scaffold uses [Scaffold.resizeToAvoidBottomInset] `false`, set
/// [padForKeyboard] so this bar lifts with [MediaQuery.viewInsets] (keyboard).
/// When resize is `true`, the scaffold already insets the layout — keep
/// [padForKeyboard] false to avoid double-applying the keyboard inset.
class ProfilePrimaryActionBar extends StatelessWidget {
  const ProfilePrimaryActionBar({
    super.key,
    required this.child,
    this.padForKeyboard = true,
  });

  final Widget child;

  /// When true, adds bottom padding equal to the keyboard height (for screens
  /// that use [Scaffold.resizeToAvoidBottomInset] `false`).
  final bool padForKeyboard;

  @override
  Widget build(BuildContext context) {
    final double keyboardBottom = padForKeyboard
        ? MediaQuery.viewInsetsOf(context).bottom
        : 0;
    return AnimatedPadding(
      duration: AppMotion.medium,
      curve: AppMotion.smooth,
      padding: EdgeInsets.only(bottom: keyboardBottom),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: child,
      ),
    );
  }
}
