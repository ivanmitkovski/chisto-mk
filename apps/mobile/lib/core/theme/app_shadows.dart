import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';

/// Shared elevation shadows — use instead of ad-hoc [BoxShadow] lists in features.
abstract final class AppShadows {
  const AppShadows._();

  static List<BoxShadow> softCard(ColorScheme colorScheme) => <BoxShadow>[
        BoxShadow(
          color: colorScheme.shadow.withValues(alpha: 0.04),
          blurRadius: AppSpacing.sm,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> card(ColorScheme colorScheme) => <BoxShadow>[
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

  static List<BoxShadow> cardPressed(ColorScheme colorScheme) => <BoxShadow>[
        BoxShadow(
          color: colorScheme.shadow.withValues(alpha: 0.06),
          blurRadius: AppSpacing.sm,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> panel(ColorScheme colorScheme) => <BoxShadow>[
        BoxShadow(
          color: colorScheme.shadow.withValues(alpha: 0.08),
          blurRadius: AppSpacing.lg,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> sheet(ColorScheme colorScheme) => <BoxShadow>[
        BoxShadow(
          color: colorScheme.shadow.withValues(alpha: 0.12),
          blurRadius: AppSpacing.xl,
          offset: const Offset(0, -4),
        ),
      ];

  static List<BoxShadow> floatingPill(ColorScheme colorScheme) => <BoxShadow>[
        BoxShadow(
          color: AppColors.primaryDark.withValues(alpha: 0.12),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> bottomBarLift(ColorScheme colorScheme) => <BoxShadow>[
        BoxShadow(
          color: colorScheme.shadow.withValues(alpha: 0.08),
          blurRadius: 12,
          offset: const Offset(0, -2),
        ),
      ];

  static List<BoxShadow> mediaHero(ColorScheme colorScheme) => <BoxShadow>[
        BoxShadow(
          color: AppColors.primaryDark.withValues(alpha: 0.08),
          blurRadius: 28,
          offset: const Offset(0, 14),
        ),
      ];
}
