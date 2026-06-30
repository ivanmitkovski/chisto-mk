import { detectAllowedImageMimeFromBuffer } from '../../src/common/utils/detect-allowed-image-mime-from-buffer';

describe('detectAllowedImageMimeFromBuffer', () => {
  it('detects JPEG', () => {
    const buf = Buffer.from([0xff, 0xd8, 0xff, 0xe0, 0x00, 0x10]);
    expect(detectAllowedImageMimeFromBuffer(buf)).toBe('image/jpeg');
  });

  it('detects PNG', () => {
    const buf = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a, 0x00]);
    expect(detectAllowedImageMimeFromBuffer(buf)).toBe('image/png');
  });

  it('detects WebP', () => {
    const buf = Buffer.alloc(12);
    buf.write('RIFF', 0);
    buf.write('WEBP', 8);
    expect(detectAllowedImageMimeFromBuffer(buf)).toBe('image/webp');
  });

  it('returns null for unknown', () => {
    expect(detectAllowedImageMimeFromBuffer(Buffer.from([0x00, 0x01, 0x02]))).toBeNull();
  });
});
