import { describe, expect, it } from 'vitest';
import {
  getNewsMediaGuidanceParams,
  NEWS_COVER_RECOMMENDED_HEIGHT,
  NEWS_COVER_RECOMMENDED_WIDTH,
  NEWS_GALLERY_RECOMMENDED_HEIGHT,
  NEWS_GALLERY_RECOMMENDED_WIDTH,
  NEWS_MEDIA_LIMITS,
} from './news-media-guidance';

describe('news-media-guidance', () => {
  it('matches landing cover aspect ratio', () => {
    const ratio = NEWS_COVER_RECOMMENDED_WIDTH / NEWS_COVER_RECOMMENDED_HEIGHT;
    expect(ratio).toBeCloseTo(21 / 9, 2);
  });

  it('matches landing gallery aspect ratio', () => {
    const ratio = NEWS_GALLERY_RECOMMENDED_WIDTH / NEWS_GALLERY_RECOMMENDED_HEIGHT;
    expect(ratio).toBeCloseTo(4 / 3, 2);
  });

  it('exposes upload limits aligned with validation', () => {
    expect(NEWS_MEDIA_LIMITS.coverMaxMb).toBe(25);
    expect(NEWS_MEDIA_LIMITS.inlineImageMaxMb).toBe(10);
    expect(NEWS_MEDIA_LIMITS.videoMaxMb).toBe(25);
    expect(NEWS_MEDIA_LIMITS.imageMinPx).toBe(128);
  });

  it('returns params for each guidance kind', () => {
    expect(getNewsMediaGuidanceParams('cover').maxMb).toBe(25);
    expect(getNewsMediaGuidanceParams('inlineImage').maxMb).toBe(10);
    expect(getNewsMediaGuidanceParams('cover').aspect).toBe('21:9');
    expect(getNewsMediaGuidanceParams('galleryImage').aspect).toBe('4:3');
    expect(getNewsMediaGuidanceParams('video').recommendedWidth).toBe(1080);
  });
});
