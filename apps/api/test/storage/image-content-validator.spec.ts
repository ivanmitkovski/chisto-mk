/// <reference types="jest" />
import { BadRequestException } from '@nestjs/common';
import sharp from 'sharp';
import { ImageContentValidator } from '../../src/storage/image-content-validator';

describe('ImageContentValidator', () => {
  const validator = new ImageContentValidator();
  let jpeg128: Buffer;

  beforeAll(async () => {
    jpeg128 = await sharp({
      create: { width: 128, height: 128, channels: 3, background: { r: 90, g: 120, b: 140 } },
    })
      .jpeg()
      .toBuffer();
  });

  it('accepts a 128×128 JPEG buffer', () => {
    const out = validator.assertReportImage(
      {
        buffer: jpeg128,
        mimetype: 'image/jpeg',
        size: jpeg128.length,
        originalname: 'x.jpg',
      },
      { maxBytes: 1024 * 1024 },
    );
    expect(out.mime).toBe('image/jpeg');
  });

  it('rejects non-image buffers', () => {
    expect(() =>
      validator.assertReportImage(
        {
          buffer: Buffer.from('not an image'),
          mimetype: 'image/jpeg',
          size: 12,
          originalname: 'x.jpg',
        },
        { maxBytes: 1024 },
      ),
    ).toThrow(BadRequestException);
  });
});
