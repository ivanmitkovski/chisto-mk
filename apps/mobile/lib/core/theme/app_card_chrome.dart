import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';

/// Shared Material 3-style elevation for event discovery cards ([EcoEventCard],
/// [HeroEventCard] outer shell, list skeletons).
///
/// Border and shadow values stay in sync across surfaces; only [EcoEventCard] uses
/// a pressed variant (softer shadow, no second layer).
abstract final class AppCardChrome {
  const AppCardChrome._();

  static BorderRadius get _cardRadius =>
      BorderRadius.circular(AppSpacing.radiusCard);

  static List<BoxShadow> _defaultShadowPair(ColorScheme colorScheme) =>
      <BoxShadow>[
        BoxShadow(
          color: colorScheme.shadow.withValues(alpha: 0.06),
          blurRadius: AppSpacing.md,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: colorScheme.shadow.withValues(alpha: 0.1),
          blurRadius: AppSpacing.lg,
          offset: const Offset(0, 8),
        ),
      ];

  /// List row + list skeleton: neutral panel fill (avoids seed-tinted
  /// [ColorScheme.surfaceContainerHighest] on green seeds) + outline + elevation.
  static BoxDecoration discoveryListCard(ColorScheme colorScheme) =>
      BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: _cardRadius,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.75),
        ),
        boxShadow: _defaultShadowPair(colorScheme),
      );

  /// [EcoEventCard] pressed: same fill and border; reduced shadow (no second layer).
  static BoxDecoration discoveryListCardPressed(ColorScheme colorScheme) =>
      BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: _cardRadius,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.75),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: AppSpacing.sm,
            offset: const Offset(0, 2),
          ),
        ],
      );

  /// [HeroEventCard] / [_HeroEventSkeleton] outer: border + shadows only (media fills).
  static BoxDecoration discoveryHeroOuter(ColorScheme colorScheme) =>
      BoxDecoration(
        borderRadius: _cardRadius,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.75),
        ),
        boxShadow: _defaultShadowPair(colorScheme),
      );
}
