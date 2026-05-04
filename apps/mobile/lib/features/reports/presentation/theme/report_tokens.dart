import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_spacing.dart';

/// Layout metrics for the reports vertical (values not covered by [AppSpacing]).
class ReportTokens {
  const ReportTokens._();

  /// Minimum width for the label column in dense detail rows (wraps at large text).
  static const double detailRowLabelMinWidth = 96;

  /// Evidence hero / gallery aspect ratio.
  static const double evidenceAspectRatio = 16 / 9;

  /// Icon size inside the evidence gallery glass pill.
  static const double galleryGlassIconSize = 13;

  /// Horizontal gap between gallery pill icon and label (matches compact chip rhythm).
  static const double galleryGlassIconTextGap = AppSpacing.xs;

  /// Outer padding for the report detail sheet header block (handle + title row).
  static EdgeInsets detailHeaderPadding() => const EdgeInsets.fromLTRB(
    AppSpacing.lg,
    AppSpacing.sm,
    AppSpacing.lg,
    AppSpacing.sm,
  );

  /// Minimum list card row height (comfortable tap target).
  static const double listCardMinTapHeight = 56;

}
