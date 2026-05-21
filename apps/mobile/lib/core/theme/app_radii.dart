import 'package:flutter/material.dart';

import 'package:chisto_mobile/core/theme/app_spacing.dart';

/// [BorderRadius] getters aligned with [AppSpacing.radius*] tokens.
abstract final class AppRadii {
  const AppRadii._();

  static BorderRadius get xs => BorderRadius.circular(AppSpacing.radiusXs);
  static BorderRadius get handle => BorderRadius.circular(AppSpacing.radiusHandle);
  static BorderRadius get chatMicro => BorderRadius.circular(AppSpacing.radiusChatMicro);
  static BorderRadius get progress => BorderRadius.circular(AppSpacing.radiusProgress);
  static BorderRadius get sm => BorderRadius.circular(AppSpacing.radiusSm);
  static BorderRadius get md => BorderRadius.circular(AppSpacing.radiusMd);
  static BorderRadius get lg => BorderRadius.circular(AppSpacing.radiusLg);
  static BorderRadius get r18 => BorderRadius.circular(AppSpacing.radius18);
  static BorderRadius get xl => BorderRadius.circular(AppSpacing.radiusXl);
  static BorderRadius get sheet => BorderRadius.circular(AppSpacing.radiusSheet);
  static BorderRadius get card => BorderRadius.circular(AppSpacing.radiusCard);
  static BorderRadius get pill => BorderRadius.circular(AppSpacing.radiusPill);
  static BorderRadius get circle => BorderRadius.circular(AppSpacing.radiusCircle);

  static BorderRadius onlyTopSheet() => const BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusSheet),
      );
}
