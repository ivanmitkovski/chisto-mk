import { describe, expect, it } from 'vitest';
import { isSvgMediaUrl } from './is-svg-media-url';

describe('isSvgMediaUrl', () => {
  it('detects local SVG paths', () => {
    expect(isSvgMediaUrl('/news/cover.svg')).toBe(true);
    expect(isSvgMediaUrl('/news/cover.png')).toBe(false);
  });

  it('detects presigned remote SVG URLs', () => {
    expect(
      isSvgMediaUrl(
        'https://bucket.s3.amazonaws.com/news/logo.svg?X-Amz-Signature=abc',
      ),
    ).toBe(true);
  });
});
