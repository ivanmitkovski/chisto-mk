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
