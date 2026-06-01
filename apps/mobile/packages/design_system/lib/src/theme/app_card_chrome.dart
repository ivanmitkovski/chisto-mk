import 'package:design_system/src/theme/app_colors.dart';
import 'package:design_system/src/theme/app_radii.dart';
import 'package:design_system/src/theme/app_shadows.dart';
import 'package:flutter/material.dart';

/// Shared Material 3-style elevation for event discovery cards ([EcoEventCard],
/// [HeroEventCard] outer shell, list skeletons).
///
/// Border and shadow values stay in sync across surfaces; only [EcoEventCard] uses
/// a pressed variant (softer shadow, no second layer).
abstract final class AppCardChrome {
  const AppCardChrome._();

  static BorderRadius get _cardRadius => AppRadii.card;

  /// List row + list skeleton: neutral panel fill (avoids seed-tinted
  /// [ColorScheme.surfaceContainerHighest] on green seeds) + outline + elevation.
  static BoxDecoration discoveryListCard(ColorScheme colorScheme) =>
      BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: _cardRadius,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.75),
        ),
        boxShadow: AppShadows.card(colorScheme),
      );

  /// [EcoEventCard] pressed: same fill and border; reduced shadow (no second layer).
  static BoxDecoration discoveryListCardPressed(ColorScheme colorScheme) =>
      BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: _cardRadius,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.75),
        ),
        boxShadow: AppShadows.cardPressed(colorScheme),
      );

  /// [HeroEventCard] / [_HeroEventSkeleton] outer: border + shadows only (media fills).
  static BoxDecoration discoveryHeroOuter(ColorScheme colorScheme) =>
      BoxDecoration(
        borderRadius: _cardRadius,
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.75),
        ),
        boxShadow: AppShadows.card(colorScheme),
      );
}
