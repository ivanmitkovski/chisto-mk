import 'package:chisto_mobile/core/theme/app_spacing.dart';

/// **Event detail layout catalog** (related widgets, not all exported here):
/// - Hero / toolbar: [HeroImageBar], [kHeroToolbarTitleInset].
/// - Body structure: [DetailContent], [DetailSectionHeader], [EventDetailGroupedPanel],
///   [EventDetailSurfaceDecoration].
/// - Sticky CTA: [StickyBottomCTA], [kEventDetailMinimumCtaReserveHeight].
/// - Async blocks: prefer [EventsAsyncSection] in `events_shared/`.
///
/// Layout tokens for [EventDetailScreen] hero, skeleton, body, and CTA reserve.
const double kEventDetailHeroExpandedHeight = 290;

/// Horizontal padding for the main detail body column (matches hero side margins).
const double kEventDetailBodyHorizontalGutter = AppSpacing.lg;

/// Minimum tap row height inside [EventDetailGroupedPanel] list rows.
const double kEventDetailGroupedRowMinHeight = 52;

/// Horizontal padding reserved by the leading/trailing action buttons in
/// [HeroImageBar] so the collapsed title never overlaps the action buttons.
const double kHeroToolbarTitleInset = AppSpacing.xl + AppSpacing.xs;

// ── Sticky bottom CTA (frosted bar) ─────────────────────────────────────────

/// Matches [PrimaryButton] intrinsic height.
const double kEventDetailCtaPrimaryButtonHeight = 56;

/// Secondary outlined button height in [StickyBottomCTA] (pill row).
const double kEventDetailCtaSecondaryButtonHeight = 54;

/// Top padding inside the CTA panel above the primary button.
const double kEventDetailCtaPanelPaddingTop = AppSpacing.md;

/// Space between primary and secondary CTA when both are shown.
const double kEventDetailCtaGapBetweenButtons = AppSpacing.sm;

/// Bottom padding inside the CTA panel (above home indicator / safe area).
const double kEventDetailCtaPanelPaddingBottom = AppSpacing.lg;

/// Backdrop blur for [StickyBottomCTA] when reduce motion is off.
const double kEventDetailStickyCtaBlurSigma = 20;

/// Panel fill opacity over the blurred content (1.0 when reduce motion is on).
const double kEventDetailStickyCtaPanelAlpha = 0.92;

/// Elevation shadow above the scroll content.
const double kEventDetailStickyCtaShadowBlurRadius = 12;
const double kEventDetailStickyCtaShadowOffsetY = -4;
const double kEventDetailStickyCtaShadowAlpha = 0.06;

/// Minimum vertical space to reserve under the scroll body when the CTA has
/// **two** rows (primary + secondary). Used as first-frame estimate before
/// [GlobalKey] measurement fills in exact height (large text / wrapping).
double kEventDetailMinimumCtaReserveHeight(double bottomSafeInset) {
  return kEventDetailCtaPanelPaddingTop +
      kEventDetailCtaPrimaryButtonHeight +
      kEventDetailCtaGapBetweenButtons +
      kEventDetailCtaSecondaryButtonHeight +
      kEventDetailCtaPanelPaddingBottom +
      bottomSafeInset;
}

/// Single-row CTA (primary only).
double kEventDetailMinimumCtaReserveHeightSingle(double bottomSafeInset) {
  return kEventDetailCtaPanelPaddingTop +
      kEventDetailCtaPrimaryButtonHeight +
      kEventDetailCtaPanelPaddingBottom +
      bottomSafeInset;
}
