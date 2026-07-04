/// <reference types="jest" />
import { NewsPostsLifecycleService } from '../../src/news/services/news-posts-lifecycle.service';

describe('NewsPostsLifecycleService', () => {
  const signedUrls = { signMany: jest.fn().mockResolvedValue(new Map()) };
  const revalidate = { triggerLandingRevalidate: jest.fn() };
  const audit = { log: jest.fn() };

  function buildService(prisma: unknown) {
    return new NewsPostsLifecycleService(
      prisma as never,
      signedUrls as never,
      revalidate as never,
      audit as never,
    );
  }

  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('rejects publish on archived posts', async () => {
    const prisma = {
      newsPost: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'p1',
          status: 'ARCHIVED',
          translations: {},
          media: [],
          coverMediaId: null,
        }),
      },
    };

    await expect(buildService(prisma).publish('p1')).rejects.toMatchObject({
      response: { code: 'NEWS_POST_ARCHIVED' },
    });
  });

  it('clears scheduledAt when publishing immediately', async () => {
    const scheduledAt = new Date(Date.now() - 60_000);
    const update = jest.fn().mockResolvedValue({
      id: 'p1',
      slug: 'due-post',
      status: 'PUBLISHED',
      scheduledAt: null,
      publishedAt: new Date(),
      category: 'RELEASE',
      featured: false,
      coverMediaId: 'cover-1',
      translations: {
        en: { title: 'T', excerpt: 'E', body: [{ type: 'paragraph', text: 'p' }] },
        mk: { title: 'T', excerpt: 'E', body: [{ type: 'paragraph', text: 'p' }] },
        sq: { title: 'T', excerpt: 'E', body: [{ type: 'paragraph', text: 'p' }] },
      },
      media: [{ id: 'cover-1', kind: 'COVER', objectKey: 'cover.jpg' }],
      coverMedia: { objectKey: 'cover.jpg' },
      createdAt: new Date(),
      updatedAt: new Date(),
    });
    const prisma = {
      newsPost: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'p1',
          status: 'SCHEDULED',
          scheduledAt,
          coverMediaId: 'cover-1',
          translations: {
            en: { title: 'T', excerpt: 'E', body: [{ type: 'paragraph', text: 'p' }] },
            mk: { title: 'T', excerpt: 'E', body: [{ type: 'paragraph', text: 'p' }] },
            sq: { title: 'T', excerpt: 'E', body: [{ type: 'paragraph', text: 'p' }] },
          },
          media: [{ id: 'cover-1', kind: 'COVER', objectKey: 'cover.jpg', altText: { en: 'Cover', mk: 'Cover', sq: 'Cover' } }],
        }),
        update,
      },
    };

    await buildService(prisma).publish('p1');

    expect(update).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          status: 'PUBLISHED',
          scheduledAt: null,
          publishedAt: expect.any(Date),
        }),
      }),
    );
  });

  it('republishes published posts with validation, audit, and revalidate', async () => {
    const publishedAt = new Date('2026-01-01T00:00:00.000Z');
    const update = jest.fn().mockResolvedValue({
      id: 'p1',
      slug: 'live-post',
      status: 'PUBLISHED',
      scheduledAt: null,
      publishedAt,
      category: 'RELEASE',
      featured: false,
      coverMediaId: 'cover-1',
      translations: {
        en: { title: 'T', excerpt: 'E', body: [{ type: 'paragraph', text: 'p' }] },
        mk: { title: 'T', excerpt: 'E', body: [{ type: 'paragraph', text: 'p' }] },
        sq: { title: 'T', excerpt: 'E', body: [{ type: 'paragraph', text: 'p' }] },
      },
      media: [{ id: 'cover-1', kind: 'COVER', objectKey: 'cover.jpg' }],
      coverMedia: { objectKey: 'cover.jpg' },
      createdAt: new Date(),
      updatedAt: new Date(),
    });
    const prisma = {
      newsPost: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'p1',
          status: 'PUBLISHED',
          scheduledAt: null,
          publishedAt,
          coverMediaId: 'cover-1',
          translations: {
            en: { title: 'T', excerpt: 'E', body: [{ type: 'paragraph', text: 'p' }] },
            mk: { title: 'T', excerpt: 'E', body: [{ type: 'paragraph', text: 'p' }] },
            sq: { title: 'T', excerpt: 'E', body: [{ type: 'paragraph', text: 'p' }] },
          },
          media: [
            {
              id: 'cover-1',
              kind: 'COVER',
              objectKey: 'cover.jpg',
              altText: { en: 'Cover', mk: 'Cover', sq: 'Cover' },
            },
          ],
        }),
        update,
      },
    };

    await buildService(prisma).publish('p1', { userId: 'admin-1' } as never);

    expect(update).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          updatedById: 'admin-1',
        }),
      }),
    );
    expect(update.mock.calls[0][0].data).not.toHaveProperty('publishedAt');
    expect(update.mock.calls[0][0].data).not.toHaveProperty('status');
    expect(audit.log).toHaveBeenCalledWith(
      expect.objectContaining({ action: 'news.post.update_publish' }),
    );
    expect(revalidate.triggerLandingRevalidate).toHaveBeenCalled();
  });

  it('rejects update-publish when published post is incomplete', async () => {
    const prisma = {
      newsPost: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'p1',
          status: 'PUBLISHED',
          scheduledAt: null,
          coverMediaId: null,
          translations: {
            en: { title: 'T', excerpt: 'E', body: [{ type: 'paragraph', text: 'p' }] },
            mk: { title: '', excerpt: '', body: [] },
            sq: { title: '', excerpt: '', body: [] },
          },
          media: [],
        }),
      },
    };

    await expect(buildService(prisma).publish('p1')).rejects.toMatchObject({
      response: { code: 'NEWS_TITLE_REQUIRED' },
    });
    expect(revalidate.triggerLandingRevalidate).not.toHaveBeenCalled();
  });

  it('keeps scheduled posts hidden until go-live', async () => {
    const scheduledAt = new Date(Date.now() + 3600_000);
    const update = jest.fn().mockResolvedValue({
      id: 'p1',
      slug: 'future-post',
      status: 'SCHEDULED',
      scheduledAt,
      publishedAt: scheduledAt,
      category: 'RELEASE',
      featured: false,
      coverMediaId: 'cover-1',
      translations: {
        en: { title: 'T', excerpt: 'E', body: [{ type: 'paragraph', text: 'p' }] },
        mk: { title: 'T', excerpt: 'E', body: [{ type: 'paragraph', text: 'p' }] },
        sq: { title: 'T', excerpt: 'E', body: [{ type: 'paragraph', text: 'p' }] },
      },
      media: [{ id: 'cover-1', kind: 'COVER', objectKey: 'cover.jpg' }],
      coverMedia: { objectKey: 'cover.jpg' },
      createdAt: new Date(),
      updatedAt: new Date(),
    });
    const prisma = {
      newsPost: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'p1',
          status: 'DRAFT',
          scheduledAt,
          coverMediaId: 'cover-1',
          translations: {
            en: { title: 'T', excerpt: 'E', body: [{ type: 'paragraph', text: 'p' }] },
            mk: { title: 'T', excerpt: 'E', body: [{ type: 'paragraph', text: 'p' }] },
            sq: { title: 'T', excerpt: 'E', body: [{ type: 'paragraph', text: 'p' }] },
          },
          media: [{ id: 'cover-1', kind: 'COVER', objectKey: 'cover.jpg', altText: { en: 'Cover', mk: 'Cover', sq: 'Cover' } }],
        }),
        update,
      },
    };

    await buildService(prisma).publish('p1');

    expect(update).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          status: 'SCHEDULED',
          scheduledAt,
          publishedAt: null,
        }),
      }),
    );
  });
});
