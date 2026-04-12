import 'package:flutter/material.dart';
import 'package:chisto_mobile/core/theme/app_colors.dart';
import 'package:chisto_mobile/core/theme/app_spacing.dart';

/// Semantic colors and geometry for event chat (derived from [AppColors] only).
///
/// Follow-ups that need product + API/schema (not UI-only): message reactions,
/// richer read receipts, link unfurl previews, voice notes.
abstract final class ChatTheme {
  static Color get canvas => AppColors.appBackground;

  static Color get canvasElevated =>
      Color.lerp(AppColors.appBackground, AppColors.white, 0.025) ?? AppColors.appBackground;

  static Color get bubbleOwnFill => AppColors.primary.withValues(alpha: 0.14);

  static Color get bubbleOwnHairline => AppColors.primary.withValues(alpha: 0.18);

  static Color get bubblePeerFill => AppColors.panelBackground;

  static Color get bubblePeerBorder => AppColors.divider.withValues(alpha: 0.45);

  static Color get bubbleDeletedFill => AppColors.inputFill.withValues(alpha: 0.6);

  static Color get bubbleFailedFill => AppColors.accentDanger.withValues(alpha: 0.06);

  static List<BoxShadow> get bubblePeerShadow => <BoxShadow>[
        BoxShadow(color: AppColors.shadowLight, blurRadius: 6, offset: const Offset(0, 1)),
      ];

  static List<BoxShadow> get bubbleOwnShadow => <BoxShadow>[
        BoxShadow(color: AppColors.shadowLight, blurRadius: 3, offset: const Offset(0, 1)),
      ];

  static Color get metaText => AppColors.textMuted;

  static Color get replyQuoteFill => AppColors.inputFill.withValues(alpha: 0.92);

  static Color get replyQuoteBar => AppColors.primary.withValues(alpha: 0.45);

  static Color highlightBorder(bool highlighted) =>
      highlighted ? AppColors.primary.withValues(alpha: 0.75) : bubblePeerBorder;

  static double highlightBorderWidth(bool highlighted) => highlighted ? 1.5 : 0.5;

  static Color bubbleNormalBorder(bool own) =>
      own ? bubbleOwnHairline : bubblePeerBorder;

  static Color get failedBorder => AppColors.accentDanger.withValues(alpha: 0.55);

  static List<BoxShadow> highlightPulse(double t) {
    final double a = 0.08 + 0.06 * t;
    return <BoxShadow>[
      BoxShadow(
        color: AppColors.primary.withValues(alpha: a),
        blurRadius: 10 + 4 * t,
        spreadRadius: 0.5,
      ),
    ];
  }

  /// Avatar color from palette, deterministic by author id hash.
  static Color avatarColor(String authorId) {
    final int idx = authorId.hashCode.abs() % AppColors.avatarPalette.length;
    return AppColors.avatarPalette[idx];
  }

  static const double avatarSize = 28;
  static const double avatarGap = AppSpacing.sm;

  /// Space between consecutive rows in the reversed chat list (below older, above newer).
  static const double bubbleStackGap = AppSpacing.md;

  static BorderRadiusGeometry bubbleRadius({
    required bool own,
    required bool isFirstInGroup,
    required bool isLastInGroup,
  }) {
    const double main = 18.0;
    const double mid = 12.0;
    const double tail = 4.0;

    if (own) {
      return BorderRadiusDirectional.only(
        topStart: const Radius.circular(main),
        topEnd: Radius.circular(isFirstInGroup ? main : mid),
        bottomStart: const Radius.circular(main),
        bottomEnd: Radius.circular(isLastInGroup ? tail : mid),
      );
    }
    return BorderRadiusDirectional.only(
      topStart: Radius.circular(isFirstInGroup ? main : mid),
      topEnd: const Radius.circular(main),
      bottomStart: Radius.circular(isLastInGroup ? tail : mid),
      bottomEnd: const Radius.circular(main),
    );
  }

  static BorderRadius get bubbleRadiusSymmetric => BorderRadius.circular(18);
}
