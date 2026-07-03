/// <reference types="jest" />
import { NewsImageProcessor, NEWS_SVG_MAX_BYTES } from '../../src/news/services/news-image-processor';

const VALID_SVG = Buffer.from(
  '<svg xmlns="http://www.w3.org/2000/svg" width="200" height="100" viewBox="0 0 200 100"><rect width="200" height="100" fill="#2FD788"/></svg>',
  'utf8',
);

const MALICIOUS_SVG = Buffer.from(
  '<svg xmlns="http://www.w3.org/2000/svg"><foreignObject><div>unsafe</div></foreignObject><rect width="10" height="10"/></svg>',
  'utf8',
);

describe('NewsImageProcessor SVG', () => {
  const processor = new NewsImageProcessor();

  it('accepts valid SVG and returns sanitized bytes', async () => {
    const result = await processor.process(
      {
        buffer: VALID_SVG,
        mimetype: 'image/svg+xml',
        size: VALID_SVG.length,
        originalname: 'logo.svg',
      },
      10 * 1024 * 1024,
    );

    expect(result.mime).toBe('image/svg+xml');
    expect(result.ext).toBe('svg');
    expect(result.width).toBe(200);
    expect(result.height).toBe(100);
    expect(result.buffer.toString('utf8')).not.toContain('<script');
  });

  it('rejects SVG with script tags', async () => {
    await expect(
      processor.process(
        {
          buffer: MALICIOUS_SVG,
          mimetype: 'image/svg+xml',
          size: MALICIOUS_SVG.length,
          originalname: 'bad.svg',
        },
        10 * 1024 * 1024,
      ),
    ).rejects.toMatchObject({
      response: { code: 'NEWS_UNSAFE_SVG' },
    });
  });

  it('rejects declared MIME mismatch for SVG content', async () => {
    await expect(
      processor.process(
        {
          buffer: VALID_SVG,
          mimetype: 'image/png',
          size: VALID_SVG.length,
          originalname: 'logo.svg',
        },
        10 * 1024 * 1024,
      ),
    ).rejects.toMatchObject({
      response: { code: 'NEWS_IMAGE_TYPE_MISMATCH' },
    });
  });

  it('rejects oversized SVG', async () => {
    const huge = Buffer.alloc(NEWS_SVG_MAX_BYTES + 1, 'a');
    const prefix = Buffer.from('<svg xmlns="http://www.w3.org/2000/svg">', 'utf8');
    prefix.copy(huge);

    await expect(
      processor.process(
        {
          buffer: huge,
          mimetype: 'image/svg+xml',
          size: huge.length,
          originalname: 'huge.svg',
        },
        10 * 1024 * 1024,
      ),
    ).rejects.toMatchObject({
      response: { code: 'NEWS_IMAGE_TOO_LARGE' },
    });
  });
});
