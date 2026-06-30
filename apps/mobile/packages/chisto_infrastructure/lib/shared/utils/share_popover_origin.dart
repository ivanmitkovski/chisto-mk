import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Global rect for [Share.share] / [Share.shareXFiles] on **iOS and iPadOS**.
///
/// The platform requires a **non-zero** origin within the source view; otherwise
/// `UIActivityViewController` throws (e.g. `sharePositionOrigin` with zero size).
/// Anchor is placed in the **top-trailing** area to match a typical share action.
Rect sharePopoverOrigin(BuildContext context) {
  final Size screen = MediaQuery.sizeOf(context);
  final EdgeInsets pad = MediaQuery.paddingOf(context);
  const double margin = 12;
  const double extent = 48;
  final double maxW = math.max(1, screen.width - 2 * margin);
  final double maxH = math.max(1, screen.height - 2 * margin);
  final double w = math.min(extent, maxW);
  final double h = math.min(extent, maxH);
  final double maxLeft = math.max(margin, screen.width - w - margin);
  final double left = (screen.width - w - margin).clamp(margin, maxLeft);
  final double maxTop = math.max(margin, screen.height - h - margin);
  final double top = (pad.top + margin).clamp(margin, maxTop);
  return Rect.fromLTWH(left, top, w, h);
}
