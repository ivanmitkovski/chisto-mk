import { describe, expect, it } from 'vitest';
import {
  NEWS_COVER_MAX_BYTES,
  NEWS_INLINE_IMAGE_MAX_BYTES,
  newsRasterImageMaxBytes,
  newsRasterImageMaxMb,
} from './constants';

describe('news upload limits', () => {
  it('allows larger covers than inline raster images', () => {
    expect(NEWS_COVER_MAX_BYTES).toBeGreaterThan(NEWS_INLINE_IMAGE_MAX_BYTES);
    expect(newsRasterImageMaxMb('cover')).toBe(25);
    expect(newsRasterImageMaxMb('inline_image')).toBe(10);
    expect(newsRasterImageMaxBytes('cover')).toBe(NEWS_COVER_MAX_BYTES);
  });
});
