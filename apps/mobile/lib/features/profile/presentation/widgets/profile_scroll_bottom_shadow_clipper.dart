import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_spacing.dart';

/// Extends the clip rect below the scroll viewport so card shadows are not cut
/// off. Top stays at 0 so list content never paints into headers above the list.
///
/// Used with [NoOverscrollOverlayScrollBehavior] on profile scroll surfaces so
/// stretch/glow indicators do not paint over the last rows.
class ProfileScrollBottomShadowClipper extends CustomClipper<Rect> {
  const ProfileScrollBottomShadowClipper({required this.bottomExtension});

  final double bottomExtension;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, 0, size.width, size.height + bottomExtension);

  @override
  bool shouldReclip(covariant ProfileScrollBottomShadowClipper oldClipper) =>
      oldClipper.bottomExtension != bottomExtension;
}

/// Default extension used by profile tab and points history scroll chrome.
const double kProfileScrollBottomShadowExtension =
    AppSpacing.xxl + AppSpacing.xl;
