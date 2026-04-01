import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_motion.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';

/// Bottom bar for profile form screens: same insets as sibling flows, and lifts
/// with the keyboard so the primary action stays reachable while typing.
class ProfilePrimaryActionBar extends StatelessWidget {
  const ProfilePrimaryActionBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: AppMotion.medium,
      curve: AppMotion.smooth,
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
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
