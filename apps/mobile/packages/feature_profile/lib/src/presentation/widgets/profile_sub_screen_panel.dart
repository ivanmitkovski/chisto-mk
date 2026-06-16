import 'package:chisto_infrastructure/core/theme/app_colors.dart';
import 'package:chisto_infrastructure/core/theme/app_spacing.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Fills remaining height below a profile sub-screen header.
///
/// [flush] keeps the same gray as [AppColors.appBackground] (e.g. weekly rankings).
/// Default sheet mode uses a white top-rounded panel with elevation.
///
/// Caller wraps this in [Expanded]. Use [scrollBottomPadding] for list bottom insets
/// when [SafeArea] bottom is disabled on the scaffold body.
class ProfileSubScreenPanel extends StatelessWidget {
  const ProfileSubScreenPanel({
    super.key,
    required this.child,
    this.flush = false,
  });

  final Widget child;

  /// Gray fill that extends to the physical bottom — no sheet chrome.
  final bool flush;

  static double scrollBottomPadding(BuildContext context) {
    return MediaQuery.paddingOf(context).bottom + AppSpacing.xl;
  }

  @override
  Widget build(BuildContext context) {
    if (flush) {
      return ColoredBox(color: AppColors.appBackground, child: child);
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: AppRadii.onlyTopSheet(),
        boxShadow: AppShadows.panel(Theme.of(context).colorScheme),
      ),
      child: ClipRRect(borderRadius: AppRadii.onlyTopSheet(), child: child),
    );
  }
}
