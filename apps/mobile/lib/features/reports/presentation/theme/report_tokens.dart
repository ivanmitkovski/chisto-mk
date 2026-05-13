import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_spacing.dart';
import 'package:chisto_mobile/features/reports/domain/report_field_limits.dart';

/// Layout metrics for the reports vertical (values not covered by [AppSpacing]).
class ReportTokens {
  const ReportTokens._();

  static int get maxTitleLength => ReportFieldLimits.maxTitleLength;
  static int get maxDescriptionLength => ReportFieldLimits.maxDescriptionLength;
  static int get maxPhotos => ReportFieldLimits.maxPhotos;

  /// Paginated "My reports" page size (see [ReportsListController.pageSize]).
  static const int myReportsPageSize = 20;

  /// Primary CTA height in new-report bottom bar.
  static const double wizardBottomBarCtaHeight = 52;

  /// Location step confirm pin button height.
  static const double locationConfirmButtonHeight = 48;

  /// Map overlay "use current location" control.
  static const double locationGpsButtonSize = 44;

  /// Compact address line under the map.
  static const double locationAddressFontSize = 13;

  /// [AnimatedSwitcher] horizontal slide for wizard stage body.
  static const double wizardStageSlideOffset = 0.03;

  /// Photo grid cell aspect (square thumbs).
  static const double photoGridAspectRatio = 1.0;

  static const double photoGridSpacing = 8;

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

  /// Debounce after map pan before reverse geocode (battery / API churn).
  static const Duration locationGeocodeDebounceMap = Duration(milliseconds: 700);

  /// One-shot geocode after GPS fix (snappier feedback).
  static const Duration locationGeocodeDebounceGps = Duration(milliseconds: 400);

  /// Auto-confirm pin after user stops panning (see [LocationPickerController]).
  static const Duration locationAutoConfirmStable = Duration(milliseconds: 1500);
}
