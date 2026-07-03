import { NEWS_IMAGE_MIN_DIMENSION, NEWS_VIDEO_MAX_BYTES, newsRasterImageMaxMb } from './news-media-validation';

/** Article hero on the landing site (`aspect-[21/9]`). */
export const NEWS_COVER_ASPECT = '21:9' as const;
export const NEWS_COVER_RECOMMENDED_WIDTH = 2100;
export const NEWS_COVER_RECOMMENDED_HEIGHT = 900;

/** Inline body images — full width within the article column. */
export const NEWS_INLINE_IMAGE_RECOMMENDED_WIDTH = 1920;

/** Gallery carousel slides on the landing site (`aspect-[4/3]`). */
export const NEWS_GALLERY_ASPECT = '4:3' as const;
export const NEWS_GALLERY_RECOMMENDED_WIDTH = 1600;
export const NEWS_GALLERY_RECOMMENDED_HEIGHT = 1200;

/** Inline video — 1080p is a practical upper bound before the 25 MB cap. */
export const NEWS_VIDEO_RECOMMENDED_WIDTH = 1920;
export const NEWS_VIDEO_RECOMMENDED_HEIGHT = 1080;

export const NEWS_IMAGE_MAX_DIMENSION = 8192;

export const NEWS_MEDIA_LIMITS = {
  coverMaxMb: newsRasterImageMaxMb('cover'),
  inlineImageMaxMb: newsRasterImageMaxMb('inline_image'),
  videoMaxMb: Math.round(NEWS_VIDEO_MAX_BYTES / (1024 * 1024)),
  imageMinPx: NEWS_IMAGE_MIN_DIMENSION,
  imageMaxPx: NEWS_IMAGE_MAX_DIMENSION,
} as const;

export type NewsMediaGuidanceKind = 'cover' | 'inlineImage' | 'galleryImage' | 'video';

export function getNewsMediaGuidanceParams(kind: NewsMediaGuidanceKind) {
  const { coverMaxMb, inlineImageMaxMb, videoMaxMb, imageMinPx } = NEWS_MEDIA_LIMITS;

  switch (kind) {
    case 'cover':
      return {
        width: NEWS_COVER_RECOMMENDED_WIDTH,
        height: NEWS_COVER_RECOMMENDED_HEIGHT,
        aspect: NEWS_COVER_ASPECT,
        maxMb: coverMaxMb,
        minPx: imageMinPx,
      };
    case 'inlineImage':
      return {
        recommendedWidth: NEWS_INLINE_IMAGE_RECOMMENDED_WIDTH,
        minPx: imageMinPx,
        maxPx: NEWS_IMAGE_MAX_DIMENSION,
        maxMb: inlineImageMaxMb,
      };
    case 'galleryImage':
      return {
        width: NEWS_GALLERY_RECOMMENDED_WIDTH,
        height: NEWS_GALLERY_RECOMMENDED_HEIGHT,
        aspect: NEWS_GALLERY_ASPECT,
        maxMb: inlineImageMaxMb,
        minPx: imageMinPx,
      };
    case 'video':
      return {
        recommendedWidth: 1080,
        width: NEWS_VIDEO_RECOMMENDED_WIDTH,
        height: NEWS_VIDEO_RECOMMENDED_HEIGHT,
        maxMb: videoMaxMb,
      };
  }
}

export const NEWS_MEDIA_GUIDANCE_MESSAGE_KEY: Record<NewsMediaGuidanceKind, string> = {
  cover: 'mediaGuidance.cover',
  inlineImage: 'mediaGuidance.inlineImage',
  galleryImage: 'mediaGuidance.galleryImage',
  video: 'mediaGuidance.video',
};
