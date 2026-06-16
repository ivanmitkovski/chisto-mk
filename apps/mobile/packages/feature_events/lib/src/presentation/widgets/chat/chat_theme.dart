import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Semantic colors and geometry for event chat (bubbles use [ColorScheme] where noted).
///
/// Follow-ups that need product + API/schema (not UI-only): message reactions,
/// richer read receipts, link unfurl previews, voice notes.
abstract final class ChatTheme {
  static Color surfaceCanvas(ColorScheme colorScheme) =>
      AppColors.appBackground;

  static Color surfaceCanvasElevated(ColorScheme colorScheme) =>
      AppColors.panelBackground;

  static Color get bubbleOwnFill => AppColors.primary.withValues(alpha: 0.14);

  static Color get bubbleOwnHairline =>
      AppColors.primary.withValues(alpha: 0.18);

  static Color get bubblePeerFill => AppColors.panelBackground;

  static Color get bubblePeerBorder =>
      AppColors.divider.withValues(alpha: 0.45);

  static Color get bubbleDeletedFill =>
      AppColors.inputFill.withValues(alpha: 0.6);

  static Color get bubbleFailedFill => AppColors.error.withValues(alpha: 0.06);

  static List<BoxShadow> get bubblePeerShadow => AppShadows.chatBubblePeer();

  static List<BoxShadow> get bubbleOwnShadow => AppShadows.chatBubbleOwn();

  static Color get metaText => AppColors.textMuted;

  static Color get replyQuoteFill =>
      AppColors.inputFill.withValues(alpha: 0.92);

  static Color get replyQuoteBar => AppColors.primary.withValues(alpha: 0.45);

  static Color highlightBorder({required bool highlighted}) => highlighted
      ? AppColors.primary.withValues(alpha: 0.75)
      : bubblePeerBorder;

  static double highlightBorderWidth({required bool highlighted}) =>
      highlighted ? 1.5 : 0.5;

  static Color bubbleNormalBorder({required bool own}) =>
      own ? bubbleOwnHairline : bubblePeerBorder;

  static Color get failedBorder => AppColors.error.withValues(alpha: 0.55);

  static List<BoxShadow> highlightPulse(double t) =>
      AppShadows.chatHighlightPulse(t);

  /// Avatar color from palette, deterministic by author id hash.
  static Color avatarColor(String authorId) {
    final int idx = authorId.hashCode.abs() % AppColors.avatarPalette.length;
    return AppColors.avatarPalette[idx];
  }

  static const double avatarSize = 28;
  static const double avatarGap = AppSpacing.sm;

  /// Tight vertical gap between consecutive bubbles from the same sender (Instagram-style stack).
  static const double bubbleStackGapWithinCluster = AppSpacing.xxs;

  /// Larger gap when the sender changes, around system messages, or after a day break (new “thread”).
  static const double bubbleStackGapBetweenClusters = AppSpacing.sm;

  static BorderRadiusGeometry bubbleRadius({
    required bool own,
    required bool isFirstInGroup,
    required bool isLastInGroup,
  }) {
    const double main = 18;
    const double mid = 12;
    const double tail = 4;

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

  static BorderRadius get bubbleRadiusSymmetric =>
      BorderRadius.circular(AppSpacing.radius18);
}
