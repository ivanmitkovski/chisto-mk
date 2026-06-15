import { SitesSavedListService } from '../../src/sites/services/sites-saved-list.service';

describe('SitesSavedListService', () => {
  function buildService() {
    const prisma = {
      siteSave: {
        count: jest.fn(async () => 2),
        findMany: jest.fn(async () => [
          {
            site: {
              id: 'site_a',
              latitude: 41.99,
              longitude: 21.43,
              description: 'A',
              status: 'VERIFIED',
              upvotesCount: 3,
              commentsCount: 1,
              sharesCount: 0,
              createdAt: new Date('2026-05-01T00:00:00.000Z'),
              reports: [],
              votes: [],
              saves: [{ id: 'save_1' }],
              _count: { reports: 0 },
            },
          },
        ]),
      },
    };
    const reportsUploadService = {
      signUrls: jest.fn(async (urls: string[]) => urls),
      signPrivateObjectKey: jest.fn(async () => null),
    };
    const siteResolutionQuery = {
      getViewerStatusBySiteIds: jest.fn(async () => new Map([['site_a', 'pending']])),
    };
    return {
      service: new SitesSavedListService(
        prisma as never,
        reportsUploadService as never,
        siteResolutionQuery as never,
      ),
      prisma,
      siteResolutionQuery,
    };
  }

  it('returns saved sites with isSavedByMe true and pagination cursor', async () => {
    const { service } = buildService();
    const out = await service.listSavedForUser(
      { userId: 'user_1' } as never,
      { page: 1, limit: 1 } as never,
    );
    expect(out.data).toHaveLength(1);
    expect(out.data[0].isSavedByMe).toBe(true);
    expect(out.data[0].viewerResolutionStatus).toBe('pending');
    expect(out.meta.nextCursor).toBe('2');
    expect(out.feedVariant).toBe('v1');
  });

  it('returns null nextCursor on last page', async () => {
    const { service, prisma } = buildService();
    (prisma.siteSave.count as jest.Mock).mockResolvedValueOnce(1);
    const out = await service.listSavedForUser(
      { userId: 'user_1' } as never,
      { page: 1, limit: 20 } as never,
    );
    expect(out.meta.nextCursor).toBeNull();
  });
});
