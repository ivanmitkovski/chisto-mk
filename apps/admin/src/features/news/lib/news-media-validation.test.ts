import { describe, expect, it } from 'vitest';
import { NEWS_IMAGE_MAX_BYTES, NEWS_VIDEO_MAX_BYTES, validateNewsMediaFile } from './news-media-validation';

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

  it('rejects oversize images', async () => {
    const result = await validateNewsMediaFile(
      mockFile('big.jpg', 'image/jpeg', NEWS_IMAGE_MAX_BYTES + 1),
      'inline_image',
    );
    expect(result).toEqual({ ok: false, code: 'imageTooLarge' });
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
      mockFile('clip.mp4', 'video/mp4', NEWS_VIDEO_MAX_BYTES - 1),
      'inline_video',
    );
    expect(result.ok).toBe(true);
  });

  it('accepts mov by extension when mime is missing', async () => {
    const result = await validateNewsMediaFile(
      mockFile('clip.mov', '', NEWS_VIDEO_MAX_BYTES - 1),
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
