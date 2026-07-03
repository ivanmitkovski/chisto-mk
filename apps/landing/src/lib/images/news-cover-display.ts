/**
 * Cover display tokens — keep in sync with admin `news-media-guidance.ts`
 * (recommended 2100×900, 21:9) and the article hero on news detail pages.
 */
export const NEWS_COVER_ASPECT_CLASS = "aspect-[21/9]" as const;

/** Soft backdrop when SVG covers letterbox; blends with typical promo art. */
export const NEWS_COVER_FRAME_SURFACE =
  "bg-gradient-to-br from-white via-primary/[0.04] to-gray-50";

/** Base classes for a cover image link/frame on cards and heroes. */
export function newsCoverFrameClass(...extra: Array<string | false | null | undefined>): string {
  return ["relative block overflow-hidden", NEWS_COVER_FRAME_SURFACE, NEWS_COVER_ASPECT_CLASS, ...extra.filter(Boolean)].join(" ");
}

/** Compact thumbnail frame for related-post rows (still 21:9, fixed width). */
export const NEWS_COVER_THUMB_FRAME_CLASS =
  "relative aspect-[21/9] w-24 shrink-0 overflow-hidden rounded-xl md:w-28";
