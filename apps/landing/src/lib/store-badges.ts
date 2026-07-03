/**
 * Store badge layout constants.
 *
 * Apple SVGs are 119.664×40 with no outer bleed. Google Play PNGs are 646×250
 * with ~32% vertical transparent padding baked into the asset. Matching CSS
 * height on both files makes Google look smaller — use a shared row slot instead.
 *
 * @see https://developer.apple.com/app-store/marketing/guidelines/
 * @see https://partnermarketinghub.withgoogle.com/brands/google-play/visual-identity/badge-guidelines/
 */

/** Apple on-screen minimum (px). */
export const APPLE_BADGE_HEIGHT_PX = 40;

/** Row slot height so Google Play visible artwork matches Apple (px). */
export const STORE_BADGE_ROW_HEIGHT_PX = 58;

/** Apple badge width at 40px height (from SVG aspect ratio). */
export const APPLE_BADGE_WIDTH_PX = 120;

/** Google badge width at 58px slot height (from PNG aspect ratio). */
export const GOOGLE_BADGE_WIDTH_PX = 150;

/** Symmetric transparent bleed in official Google Play badge PNGs (41px on 646px). */
export const GOOGLE_BADGE_BLEED_X_RATIO = 41 / 646;

/** Visible content width ratio inside the Google Play PNG. */
export const GOOGLE_BADGE_CONTENT_WIDTH_RATIO = 564 / 646;

/** Row slot height at md breakpoint (matches Tailwind `md:h-16`). */
export const STORE_BADGE_ROW_HEIGHT_MD_PX = 64;

/** Visible Google Play badge width after cropping transparent PNG bleed (px). */
export function googleBadgeVisibleWidthPx(rowHeightPx: number): number {
  return Math.round(GOOGLE_BADGE_CONTENT_WIDTH_RATIO * (646 / 250) * rowHeightPx);
}

export type StoreBadgeAlign = "start" | "center";
