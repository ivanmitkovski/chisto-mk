import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Design-system surfaces for event detail.
///
/// - [groupedListShell]: inset grouped metadata (location, schedule, …) — calm, low elevation.
/// - [detailModule]: secondary blocks (weather, participants, …) on the detail canvas.
/// - [elevatedCard]: legacy white card; prefer [detailModule] for new work.
///
/// Use with [ClipRRect] where children need clipping (e.g. [EventDetailGroupedPanel]).
abstract final class EventDetailSurfaceDecoration {
  static const double _kDividerBorderAlpha = 0.45;

  /// Corner radius shared by detail cards and the grouped metadata panel.
  static BorderRadius get cardBorderRadius =>
      BorderRadius.circular(AppSpacing.radiusLg);

  /// Single soft elevation shadow (tokenized color from [AppColors.shadowMedium]).
  static List<BoxShadow> get elevatedCardShadow =>
      AppShadows.eventDetailElevatedCard();

  /// Very light shadow for [detailModule] (structure without “floating white card”).
  static List<BoxShadow> get detailModuleShadow =>
      AppShadows.eventDetailModule();

  /// White panel + hairline border + optional [elevatedCardShadow].
  static BoxDecoration elevatedCard({bool includeShadow = true}) {
    return BoxDecoration(
      color: AppColors.panelBackground,
      borderRadius: cardBorderRadius,
      border: Border.all(
        color: AppColors.divider.withValues(alpha: _kDividerBorderAlpha + 0.05),
      ),
      boxShadow: includeShadow ? elevatedCardShadow : null,
    );
  }

  /// Grouped fact list shell (Settings-style): soft fill, hairline border, no heavy shadow.
  static BoxDecoration groupedListShell() {
    return BoxDecoration(
      color: AppColors.detailSurfaceGrouped,
      borderRadius: cardBorderRadius,
      border: Border.all(
        color: AppColors.divider.withValues(alpha: _kDividerBorderAlpha),
      ),
    );
  }

  /// Secondary module on the detail canvas (weather, reminder, analytics, …).
  static BoxDecoration detailModule({bool includeShadow = true}) {
    return BoxDecoration(
      color: AppColors.detailSurfaceModule,
      borderRadius: cardBorderRadius,
      border: Border.all(
        color: AppColors.divider.withValues(alpha: _kDividerBorderAlpha),
      ),
      boxShadow: includeShadow ? detailModuleShadow : null,
    );
  }
}
