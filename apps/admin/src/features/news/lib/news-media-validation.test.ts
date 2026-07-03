import { describe, expect, it } from 'vitest';
import {
  NEWS_COVER_MAX_BYTES,
  NEWS_INLINE_IMAGE_MAX_BYTES,
  NEWS_SVG_MAX_BYTES,
  newsRasterImageMaxBytes,
  newsRasterImageMaxMb,
  validateNewsMediaFile,
} from './news-media-validation';

function mockFile(name: string, type: string, size: number): File {
  const buffer = new ArrayBuffer(size);
  return new File([buffer], name, { type });
}

describe('validateNewsMediaFile', () => {
  it('accepts HEIC by mime without dimension check', async () => {
    const result = await validateNewsMediaFile(
      mockFile('photo.heic', 'image/heic', 1024),
      'inline_image',
    );
    expect(result.ok).toBe(true);
  });

  it('rejects oversize inline images', async () => {
    const result = await validateNewsMediaFile(
      mockFile('big.jpg', 'image/jpeg', NEWS_INLINE_IMAGE_MAX_BYTES + 1),
      'inline_image',
    );
    expect(result).toEqual({ ok: false, code: 'imageTooLarge', maxMb: 10 });
  });

  it('allows larger cover images than inline images', async () => {
    const size = NEWS_INLINE_IMAGE_MAX_BYTES + 1024;
    const file = mockFile('photo.heic', 'image/heic', size);
    const inline = await validateNewsMediaFile(file, 'inline_image');
    const cover = await validateNewsMediaFile(file, 'cover');

    expect(inline).toEqual({ ok: false, code: 'imageTooLarge', maxMb: 10 });
    expect(cover.ok).toBe(true);
  });

  it('rejects cover images above the cover cap', async () => {
    const result = await validateNewsMediaFile(
      mockFile('huge.jpg', 'image/jpeg', NEWS_COVER_MAX_BYTES + 1),
      'cover',
    );
    expect(result).toEqual({ ok: false, code: 'imageTooLarge', maxMb: 25 });
  });

  it('rejects oversize SVG files', async () => {
    const result = await validateNewsMediaFile(
      mockFile('logo.svg', 'image/svg+xml', NEWS_SVG_MAX_BYTES + 1),
      'cover',
    );
    expect(result).toEqual({ ok: false, code: 'imageTooLarge', maxMb: 2 });
  });

  it('rejects invalid video type', async () => {
    const result = await validateNewsMediaFile(
      mockFile('a.avi', 'video/x-msvideo', 1024),
      'inline_video',
    );
    expect(result).toEqual({ ok: false, code: 'invalidVideoType' });
  });

  it('accepts mp4 under video limit', async () => {
    const result = await validateNewsMediaFile(
      mockFile('clip.mp4', 'video/mp4', 25 * 1024 * 1024 - 1),
      'inline_video',
    );
    expect(result.ok).toBe(true);
  });

  it('accepts mov by extension when mime is missing', async () => {
    const result = await validateNewsMediaFile(
      mockFile('clip.mov', '', 25 * 1024 * 1024 - 1),
      'inline_video',
    );
    expect(result.ok).toBe(true);
  });

  it('rejects video for cover uploads', async () => {
    const result = await validateNewsMediaFile(
      mockFile('clip.mp4', 'video/mp4', 1024),
      'cover',
    );
    expect(result).toEqual({ ok: false, code: 'invalidImageType' });
  });
});

describe('newsRasterImageMaxBytes', () => {
  it('uses a higher cap for covers than inline images', () => {
    expect(newsRasterImageMaxBytes('cover')).toBe(NEWS_COVER_MAX_BYTES);
    expect(newsRasterImageMaxBytes('inline_image')).toBe(NEWS_INLINE_IMAGE_MAX_BYTES);
    expect(newsRasterImageMaxMb('cover')).toBe(25);
    expect(newsRasterImageMaxMb('inline_image')).toBe(10);
  });
});
