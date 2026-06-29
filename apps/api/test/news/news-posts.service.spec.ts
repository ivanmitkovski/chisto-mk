/// <reference types="jest" />
import { NewsPostsUpdateService } from '../../src/news/services/news-posts-update.service';

describe('NewsPostsUpdateService featured exclusivity', () => {
  it('clears featured on other posts when setting featured true', async () => {
    const updateMany = jest.fn().mockResolvedValue({ count: 1 });
    const update = jest.fn().mockResolvedValue({
      id: 'post-1',
      slug: 'a',
      category: 'RELEASE',
      status: 'DRAFT',
      publishedAt: null,
      scheduledAt: null,
      featured: true,
      translations: {
        en: { title: 'T', excerpt: 'E', body: [] },
        mk: { title: '', excerpt: '', body: [] },
        sq: { title: '', excerpt: '', body: [] },
      },
      coverMediaId: null,
      createdAt: new Date(),
      updatedAt: new Date(),
      createdById: null,
      updatedById: null,
      media: [],
      coverMedia: null,
    });
    const findUnique = jest.fn().mockResolvedValue({
      id: 'post-1',
      slug: 'a',
      status: 'DRAFT',
      featured: false,
    });

    const tx = {
      newsPost: { updateMany, update },
    };

    const prisma = {
      newsPost: { findUnique },
      $transaction: jest.fn((fn: (client: typeof tx) => Promise<unknown>) => fn(tx)),
    };

    const signedUrls = {
      signMany: jest.fn().mockResolvedValue(new Map()),
    };

    const svc = new NewsPostsUpdateService(
      prisma as never,
      signedUrls as never,
      { triggerLandingRevalidate: jest.fn() } as never,
      { createRevision: jest.fn() } as never,
    );

    await svc.update('post-1', { featured: true });

    expect(updateMany).toHaveBeenCalledWith({
      where: { id: { not: 'post-1' }, featured: true },
      data: { featured: false },
    });
  });
});
