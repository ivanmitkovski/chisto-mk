/// <reference types="jest" />
import { NewsRevisionsService } from '../../src/news/services/news-revisions.service';

describe('NewsRevisionsService', () => {
  const revalidate = { triggerLandingRevalidate: jest.fn() };
  const audit = { log: jest.fn() };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('prunes revisions beyond the cap', async () => {
    const create = jest.fn().mockResolvedValue({ id: 'rev-new' });
    const findUnique = jest.fn().mockResolvedValue({
      id: 'post-1',
      slug: 'slug',
      category: 'RELEASE',
      featured: false,
      scheduledAt: null,
      translations: {
        en: { title: 'T', excerpt: 'E', body: [] },
        mk: { title: '', excerpt: '', body: [] },
        sq: { title: '', excerpt: '', body: [] },
      },
    });
    const findMany = jest.fn().mockResolvedValue([{ id: 'old-1' }, { id: 'old-2' }]);
    const deleteMany = jest.fn().mockResolvedValue({ count: 2 });

    const prisma = {
      newsPost: { findUnique },
      newsPostRevision: { create, findMany, deleteMany },
    };

    const svc = new NewsRevisionsService(prisma as never, revalidate as never, audit as never);
    await svc.createRevision('post-1');

    expect(deleteMany).toHaveBeenCalledWith({
      where: { id: { in: ['old-1', 'old-2'] } },
    });
  });

  it('restore uses featured exclusivity, audits, and revalidates publishable posts', async () => {
    const snapshot = {
      slug: 'restored-slug',
      category: 'release',
      featured: true,
      scheduledAt: null,
      translations: {
        en: { title: 'T', excerpt: 'E', body: [{ type: 'paragraph', text: 'p' }] },
        mk: { title: 'T', excerpt: 'E', body: [{ type: 'paragraph', text: 'p' }] },
        sq: { title: 'T', excerpt: 'E', body: [{ type: 'paragraph', text: 'p' }] },
      },
    };
    const updateMany = jest.fn().mockResolvedValue({ count: 1 });
    const update = jest.fn().mockResolvedValue({
      id: 'post-1',
      slug: 'restored-slug',
      featured: true,
      media: [{ id: 'cover-1', kind: 'COVER', objectKey: 'cover.jpg' }],
      coverMedia: { objectKey: 'cover.jpg' },
    });
    const transaction = jest.fn(async (fn: (tx: unknown) => Promise<unknown>) =>
      fn({
        newsPost: { updateMany, update },
      }),
    );

    const findFirst = jest.fn().mockResolvedValue({ id: 'rev-1', snapshot });
    const findUnique = jest
      .fn()
      .mockResolvedValueOnce({ id: 'post-1', status: 'PUBLISHED', slug: 'restored-slug' })
      .mockResolvedValueOnce({
        id: 'post-1',
        status: 'PUBLISHED',
        coverMediaId: 'cover-1',
        media: [{ id: 'cover-1', kind: 'COVER' }],
      })
      .mockResolvedValueOnce({
        id: 'post-1',
        slug: 'before-restore',
        category: 'RELEASE',
        featured: false,
        scheduledAt: null,
        translations: snapshot.translations,
      });
    const create = jest.fn().mockResolvedValue({ id: 'rev-new' });
    const findMany = jest.fn().mockResolvedValue([]);

    const prisma = {
      $transaction: transaction,
      newsPost: { findUnique, update },
      newsPostRevision: { findFirst, create, findMany, deleteMany: jest.fn() },
    };

    const svc = new NewsRevisionsService(prisma as never, revalidate as never, audit as never);
    await svc.restore('post-1', 'rev-1', { userId: 'admin-1' } as never);

    expect(updateMany).toHaveBeenCalledWith({
      where: { id: { not: 'post-1' }, featured: true },
      data: { featured: false },
    });
    expect(audit.log).toHaveBeenCalledWith(
      expect.objectContaining({
        action: 'news.post.restore',
        resourceId: 'post-1',
        metadata: { slug: 'restored-slug', revisionId: 'rev-1' },
      }),
    );
    expect(revalidate.triggerLandingRevalidate).toHaveBeenCalled();
  });

  it('restore skips featured exclusivity when snapshot is not featured', async () => {
    const snapshot = {
      slug: 'restored-slug',
      category: 'release',
      featured: false,
      scheduledAt: null,
      translations: {
        en: { title: 'T', excerpt: 'E', body: [{ type: 'paragraph', text: 'p' }] },
        mk: { title: 'T', excerpt: 'E', body: [{ type: 'paragraph', text: 'p' }] },
        sq: { title: 'T', excerpt: 'E', body: [{ type: 'paragraph', text: 'p' }] },
      },
    };
    const updateMany = jest.fn();
    const update = jest.fn().mockResolvedValue({
      id: 'post-1',
      slug: 'restored-slug',
      featured: false,
      media: [{ id: 'cover-1', kind: 'COVER', objectKey: 'cover.jpg' }],
      coverMedia: { objectKey: 'cover.jpg' },
    });
    const transaction = jest.fn(async (fn: (tx: unknown) => Promise<unknown>) =>
      fn({
        newsPost: { updateMany, update },
      }),
    );

    const findFirst = jest.fn().mockResolvedValue({ id: 'rev-1', snapshot });
    const findUnique = jest
      .fn()
      .mockResolvedValueOnce({ id: 'post-1', status: 'DRAFT' })
      .mockResolvedValueOnce({
        id: 'post-1',
        slug: 'before-restore',
        category: 'RELEASE',
        featured: true,
        scheduledAt: null,
        translations: snapshot.translations,
      });
    const create = jest.fn().mockResolvedValue({ id: 'rev-new' });
    const findMany = jest.fn().mockResolvedValue([]);

    const prisma = {
      $transaction: transaction,
      newsPost: { findUnique, update },
      newsPostRevision: { findFirst, create, findMany, deleteMany: jest.fn() },
    };

    const svc = new NewsRevisionsService(prisma as never, revalidate as never, audit as never);
    await svc.restore('post-1', 'rev-1', { userId: 'admin-1' } as never);

    expect(updateMany).not.toHaveBeenCalled();
    expect(update).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ featured: false }),
      }),
    );
    expect(revalidate.triggerLandingRevalidate).not.toHaveBeenCalled();
  });

  it('clearHistory deletes all revisions and audits', async () => {
    const findUnique = jest.fn().mockResolvedValue({ id: 'post-1', slug: 'my-post' });
    const deleteMany = jest.fn().mockResolvedValue({ count: 4 });

    const prisma = {
      newsPost: { findUnique },
      newsPostRevision: { deleteMany },
    };

    const svc = new NewsRevisionsService(prisma as never, revalidate as never, audit as never);
    const result = await svc.clearHistory('post-1', { userId: 'admin-1' } as never);

    expect(deleteMany).toHaveBeenCalledWith({ where: { postId: 'post-1' } });
    expect(result).toEqual({ deleted: 4 });
    expect(audit.log).toHaveBeenCalledWith(
      expect.objectContaining({
        action: 'news.post.revisions_clear',
        resourceId: 'post-1',
        metadata: { slug: 'my-post', deleted: 4 },
      }),
    );
  });
});
