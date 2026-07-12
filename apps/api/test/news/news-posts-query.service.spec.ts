/// <reference types="jest" />
import { NewsPostsQueryService } from '../../src/news/services/news-posts-query.service';

describe('NewsPostsQueryService', () => {
  it('returns db total for listPublished without signing', async () => {
    const prisma = {
      newsPost: {
        findMany: jest.fn().mockResolvedValue([]),
        count: jest.fn().mockResolvedValue(42),
      },
    };
    const signedUrls = {
      signMany: jest.fn().mockResolvedValue(new Map()),
      getSignedUrlTtlSeconds: jest.fn().mockReturnValue(3600),
    };
    const config = { get: jest.fn().mockReturnValue('https://api.chisto.mk') };
    const svc = new NewsPostsQueryService(prisma as never, signedUrls as never, config as never);

    const result = await svc.listPublished('en', 10, 0);

    expect(result.total).toBe(42);
    expect(prisma.newsPost.count).toHaveBeenCalled();
    expect(signedUrls.signMany).not.toHaveBeenCalled();
  });

  it('redirects published media via a freshly signed URL', async () => {
    const prisma = {
      newsMedia: {
        findFirst: jest.fn().mockResolvedValue({ objectKey: 'news/p1/cover.jpg' }),
      },
    };
    const signedUrls = {
      signMany: jest.fn(),
      getSignedGetUrl: jest.fn().mockResolvedValue('https://s3.example/signed'),
      getSignedUrlTtlSeconds: jest.fn().mockReturnValue(3600),
    };
    const config = { get: jest.fn().mockReturnValue('https://api.chisto.mk') };
    const svc = new NewsPostsQueryService(prisma as never, signedUrls as never, config as never);

    await expect(svc.getPublishedMediaSignedUrl('media-1')).resolves.toBe('https://s3.example/signed');
    expect(prisma.newsMedia.findFirst).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          id: 'media-1',
          post: expect.objectContaining({ status: 'PUBLISHED' }),
        }),
      }),
    );
    expect(svc.getMediaRedirectMaxAgeSeconds()).toBe(120);
  });
});
