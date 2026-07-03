/// <reference types="jest" />
import sharp from 'sharp';
import { NewsImageProcessor } from '../../src/news/services/news-image-processor';
import { NewsMediaUploadService } from '../../src/news/services/news-media-upload.service';

describe('NewsMediaUploadService', () => {
  const imageProcessor = new NewsImageProcessor();
  let jpeg128: Buffer;

  beforeAll(async () => {
    jpeg128 = await sharp({
      create: { width: 128, height: 128, channels: 3, background: { r: 90, g: 120, b: 140 } },
    })
      .jpeg()
      .toBuffer();
  });

  function buildService(overrides?: {
    s3Enabled?: boolean;
    post?: Record<string, unknown>;
  }) {
    const prisma = {
      newsPost: {
        findUnique: jest.fn().mockResolvedValue(
          overrides?.post ?? {
            id: 'post-1',
            status: 'DRAFT',
            coverMediaId: null,
            coverMedia: null,
          },
        ),
        update: jest.fn().mockResolvedValue({}),
      },
      newsMedia: {
        create: jest.fn().mockImplementation(({ data }) =>
          Promise.resolve({ id: 'media-1', ...data }),
        ),
        delete: jest.fn().mockResolvedValue({}),
      },
    };
    const s3 = {
      enabled: overrides?.s3Enabled ?? true,
      putObject: jest.fn().mockResolvedValue(undefined),
      deleteObject: jest.fn().mockResolvedValue(undefined),
    };
    const signedUrls = {
      getSignedGetUrl: jest.fn().mockResolvedValue('https://signed.example/a.jpg'),
      invalidateKey: jest.fn(),
    };
    const revalidate = { triggerLandingRevalidate: jest.fn() };
    const audit = { log: jest.fn() };

    const svc = new NewsMediaUploadService(
      prisma as never,
      s3 as never,
      imageProcessor,
      signedUrls as never,
      revalidate as never,
      audit as never,
    );

    return { svc, prisma, s3 };
  }

  it('uploads JPEG with dimensions', async () => {
    const { svc, prisma, s3 } = buildService();
    const result = await svc.upload({
      postId: 'post-1',
      kind: 'inline_image',
      file: {
        buffer: jpeg128,
        mimetype: 'image/jpeg',
        size: jpeg128.length,
        originalname: 'cover.jpg',
      },
    });

    expect(s3.putObject).toHaveBeenCalled();
    expect(prisma.newsMedia.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          mimeType: 'image/jpeg',
          width: 128,
          height: 128,
        }),
      }),
    );
    expect(result.url).toBe('https://signed.example/a.jpg');
  });

  it('rejects oversized inline images', async () => {
    const { svc } = buildService();
    await expect(
      svc.upload({
        postId: 'post-1',
        kind: 'inline_image',
        file: {
          buffer: jpeg128,
          mimetype: 'image/jpeg',
          size: 11 * 1024 * 1024,
          originalname: 'big.jpg',
        },
      }),
    ).rejects.toMatchObject({
      response: { code: 'NEWS_IMAGE_TOO_LARGE' },
    });
  });

  it('accepts cover images larger than the inline image cap', async () => {
    const { svc, s3 } = buildService();
    const result = await svc.upload({
      postId: 'post-1',
      kind: 'cover',
      file: {
        buffer: jpeg128,
        mimetype: 'image/jpeg',
        size: 15 * 1024 * 1024,
        originalname: 'hero.jpg',
      },
    });

    expect(s3.putObject).toHaveBeenCalled();
    expect(result.url).toBe('https://signed.example/a.jpg');
  });

  it('rejects cover images above the cover cap', async () => {
    const { svc } = buildService();
    await expect(
      svc.upload({
        postId: 'post-1',
        kind: 'cover',
        file: {
          buffer: jpeg128,
          mimetype: 'image/jpeg',
          size: 26 * 1024 * 1024,
          originalname: 'huge.jpg',
        },
      }),
    ).rejects.toMatchObject({
      response: { code: 'NEWS_IMAGE_TOO_LARGE' },
    });
  });

  it('rejects tiny images', async () => {
    const tiny = await sharp({
      create: { width: 64, height: 64, channels: 3, background: { r: 0, g: 0, b: 0 } },
    })
      .jpeg()
      .toBuffer();
    const { svc } = buildService();
    await expect(
      svc.upload({
        postId: 'post-1',
        kind: 'inline_image',
        file: {
          buffer: tiny,
          mimetype: 'image/jpeg',
          size: tiny.length,
          originalname: 'tiny.jpg',
        },
      }),
    ).rejects.toMatchObject({
      response: { code: 'NEWS_IMAGE_TOO_SMALL' },
    });
  });

  it('rejects fake MP4 magic bytes', async () => {
    const { svc } = buildService();
    await expect(
      svc.upload({
        postId: 'post-1',
        kind: 'inline_video',
        file: {
          buffer: Buffer.from('not-a-video-file'),
          mimetype: 'video/mp4',
          size: 100,
          originalname: 'fake.mp4',
        },
      }),
    ).rejects.toMatchObject({
      response: { code: 'NEWS_INVALID_VIDEO_TYPE' },
    });
  });

  it('replaces cover in create → update post → delete old order', async () => {
    const callOrder: string[] = [];
    const prisma = {
      newsPost: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'post-1',
          status: 'DRAFT',
          coverMediaId: 'old-cover',
          coverMedia: { id: 'old-cover', objectKey: 'news/post-1/cover/old.webp' },
        }),
        update: jest.fn().mockImplementation(async () => {
          callOrder.push('post.update');
          return {};
        }),
      },
      newsMedia: {
        create: jest.fn().mockImplementation(async ({ data }) => {
          callOrder.push('media.create');
          return { id: 'media-new', ...data };
        }),
        delete: jest.fn().mockImplementation(async () => {
          callOrder.push('media.delete');
          return {};
        }),
      },
    };
    const s3 = {
      enabled: true,
      putObject: jest.fn().mockResolvedValue(undefined),
      deleteObject: jest.fn().mockResolvedValue(undefined),
    };
    const signedUrls = {
      getSignedGetUrl: jest.fn().mockResolvedValue('https://signed.example/new.jpg'),
      invalidateKey: jest.fn(),
    };
    const svc = new NewsMediaUploadService(
      prisma as never,
      s3 as never,
      imageProcessor,
      signedUrls as never,
      { triggerLandingRevalidate: jest.fn() } as never,
      { log: jest.fn() } as never,
    );

    await svc.upload({
      postId: 'post-1',
      kind: 'cover',
      file: {
        buffer: jpeg128,
        mimetype: 'image/jpeg',
        size: jpeg128.length,
        originalname: 'cover.jpg',
      },
    });

    expect(callOrder).toEqual(['media.create', 'post.update', 'media.delete']);
    expect(prisma.newsPost.update).toHaveBeenCalledWith({
      where: { id: 'post-1' },
      data: { coverMediaId: 'media-new' },
    });
    expect(prisma.newsMedia.delete).toHaveBeenCalledWith({ where: { id: 'old-cover' } });
    expect(signedUrls.invalidateKey).toHaveBeenCalledWith('news/post-1/cover/old.webp');
    expect(s3.deleteObject).toHaveBeenCalledWith('news/post-1/cover/old.webp');
  });

  it('throws when S3 is not configured', async () => {
    const { svc } = buildService({ s3Enabled: false });
    await expect(
      svc.upload({
        postId: 'post-1',
        kind: 'inline_image',
        file: {
          buffer: jpeg128,
          mimetype: 'image/jpeg',
          size: jpeg128.length,
          originalname: 'cover.jpg',
        },
      }),
    ).rejects.toMatchObject({
      response: { code: 'S3_NOT_CONFIGURED' },
    });
  });
});

describe('NewsImageProcessor HEIC', () => {
  it('converts HEIC buffer to WebP when sharp accepts input', async () => {
    const processor = new NewsImageProcessor();
    const webpSource = await sharp({
      create: { width: 200, height: 200, channels: 3, background: { r: 10, g: 20, b: 30 } },
    })
      .webp()
      .toBuffer();

    const result = await processor.process(
      {
        buffer: webpSource,
        mimetype: 'image/heic',
        size: webpSource.length,
        originalname: 'photo.heic',
      },
      10 * 1024 * 1024,
    );

    expect(result.mime).toBe('image/webp');
    expect(result.ext).toBe('webp');
    expect(result.width).toBeGreaterThanOrEqual(128);
  });
});
