export const MAX_BODY_BLOCKS = 50;
export const MIN_GALLERY_ITEMS = 2;
export const MAX_GALLERY_ITEMS = 12;
export const MAX_GALLERY_CAPTION_LENGTH = 500;

/** Hero cover — aligns with API multer cap (25 MB). */
export const NEWS_COVER_MAX_BYTES = 25 * 1024 * 1024;
/** Inline body images — smaller cap keeps article payloads reasonable. */
export const NEWS_INLINE_IMAGE_MAX_BYTES = 10 * 1024 * 1024;
export const NEWS_SVG_MAX_BYTES = 2 * 1024 * 1024;
export const NEWS_VIDEO_MAX_BYTES = 25 * 1024 * 1024;

export type NewsRasterUploadKind = 'cover' | 'inline_image';

export function newsRasterImageMaxBytes(kind: NewsRasterUploadKind): number {
  return kind === 'cover' ? NEWS_COVER_MAX_BYTES : NEWS_INLINE_IMAGE_MAX_BYTES;
}

export function newsRasterImageMaxMb(kind: NewsRasterUploadKind): number {
  return Math.round(newsRasterImageMaxBytes(kind) / (1024 * 1024));
}
