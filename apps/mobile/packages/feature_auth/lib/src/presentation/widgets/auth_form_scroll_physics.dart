import 'package:flutter/material.dart';

/// Scroll physics for auth forms inside [AuthShell] and related scaffolds.
///
/// When the keyboard is hidden and content fits the viewport, dragging does
/// nothing. Scrolling is enabled when the keyboard is open (field visibility,
/// drag-to-dismiss) or when content naturally overflows (large text scale,
/// error banners).
abstract final class AuthFormScrollPhysics {
  static ScrollPhysics resolve(BuildContext context) {
    final bool keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    final ScrollPhysics platform = switch (Theme.of(context).platform) {
      TargetPlatform.iOS || TargetPlatform.macOS => const BouncingScrollPhysics(),
      _ => const ClampingScrollPhysics(),
    };
    if (keyboardVisible) {
      return AlwaysScrollableScrollPhysics(parent: platform);
    }
    return platform;
  }
}
