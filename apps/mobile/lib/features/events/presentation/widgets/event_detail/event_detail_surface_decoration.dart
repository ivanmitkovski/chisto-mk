import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';

/// Design-system surfaces for event detail: panel fill, hairline border, optional soft shadow.
///
/// Use with [ClipRRect] where children need clipping (e.g. [EventDetailGroupedPanel]).
abstract final class EventDetailSurfaceDecoration {
  static const double _kDividerBorderAlpha = 0.5;

  /// Corner radius shared by detail cards and the grouped metadata panel.
  static BorderRadius get cardBorderRadius =>
      BorderRadius.circular(AppSpacing.radiusLg);

  /// Single soft elevation shadow (tokenized color from [AppColors.shadowMedium]).
  static const List<BoxShadow> elevatedCardShadow = <BoxShadow>[
    BoxShadow(
      color: AppColors.shadowMedium,
      blurRadius: 10,
      offset: Offset(0, 2),
    ),
  ];

  /// White panel + hairline border + optional [elevatedCardShadow].
  static BoxDecoration elevatedCard({bool includeShadow = true}) {
    return BoxDecoration(
      color: AppColors.panelBackground,
      borderRadius: cardBorderRadius,
      border: Border.all(
        color: AppColors.divider.withValues(alpha: _kDividerBorderAlpha),
      ),
      boxShadow: includeShadow ? elevatedCardShadow : null,
    );
  }
}
