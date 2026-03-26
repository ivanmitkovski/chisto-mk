import { SitesService } from '../../src/sites/sites.service';

describe('SitesService', () => {
  const baseUser = { userId: 'user_1' } as any;

  const buildService = (prismaMock: any, ensureSiteExists?: jest.Mock) =>
    new SitesService(
      prismaMock,
      { log: jest.fn() } as any,
      { signUrls: jest.fn(async (v: string[]) => v) } as any,
      { emitSiteCreated: jest.fn(), emitSiteUpdated: jest.fn() } as any,
      { score: jest.fn(() => 0), scoreDetailed: jest.fn(() => ({ score: 0, reasonCodes: ['test'], components: {} })) } as any,
      { ensureSiteExists: ensureSiteExists ?? jest.fn(async () => undefined) } as any,
    );

  it('rejects partial geo query (lat without lng)', async () => {
    const service = buildService({} as any);
    await expect(
      service.findAll({ lat: 41.6, page: 1, limit: 20, radiusKm: 10, sort: 'hybrid' } as any),
    ).rejects.toMatchObject({
      response: { code: 'INVALID_GEO_QUERY' },
    });
  });

  it('keeps like idempotent when already liked', async () => {
    const prismaMock = {
      siteComment: {
        findUnique: jest.fn(async () => ({
          id: 'comment_1',
          siteId: 'site_1',
          isDeleted: false,
          likesCount: 7,
        })),
      },
      $transaction: jest.fn(async (cb: any) =>
        cb({
          siteCommentLike: {
            findUnique: jest.fn(async () => ({ id: 'like_1' })),
            create: jest.fn(async () => undefined),
          },
          siteComment: {
            update: jest.fn(async () => ({ id: 'comment_1', likesCount: 8 })),
            findUniqueOrThrow: jest.fn(async () => ({ id: 'comment_1', likesCount: 7 })),
          },
        }),
      ),
    } as any;
    const service = buildService(prismaMock);

    const snapshot = await service.likeSiteComment('site_1', 'comment_1', baseUser);
    expect(snapshot).toEqual({ commentId: 'comment_1', likesCount: 7, isLikedByMe: true });
  });

  it('keeps unlike idempotent when not liked', async () => {
    const prismaMock = {
      siteComment: {
        findUnique: jest.fn(async () => ({
          id: 'comment_1',
          siteId: 'site_1',
          isDeleted: false,
          likesCount: 4,
        })),
      },
      $transaction: jest.fn(async (cb: any) =>
        cb({
          siteCommentLike: {
            deleteMany: jest.fn(async () => ({ count: 0 })),
          },
          siteComment: {
            update: jest.fn(async () => ({ id: 'comment_1', likesCount: 3 })),
            findUniqueOrThrow: jest.fn(async () => ({ id: 'comment_1', likesCount: 4 })),
          },
        }),
      ),
    } as any;
    const service = buildService(prismaMock);

    const snapshot = await service.unlikeSiteComment('site_1', 'comment_1', baseUser);
    expect(snapshot).toEqual({ commentId: 'comment_1', likesCount: 4, isLikedByMe: false });
  });

  it('uses hybrid ranking even when geo context is present', async () => {
    const siteNear = {
      id: 'site_near',
      createdAt: new Date('2026-03-27T08:00:00.000Z'),
      latitude: 41.61,
      longitude: 21.75,
      status: 'REPORTED',
      upvotesCount: 2,
      commentsCount: 0,
      savesCount: 0,
      sharesCount: 0,
      reports: [
        {
          title: 'Near',
          description: 'Near',
          mediaUrls: [] as string[],
          category: 'illegal',
          createdAt: new Date('2026-03-27T08:00:00.000Z'),
          reportNumber: 'R-1',
        },
      ],
      votes: [],
      saves: [],
      _count: { reports: 1 },
    };
    const siteFarHighQuality = {
      id: 'site_far_high',
      createdAt: new Date('2026-03-27T08:00:00.000Z'),
      latitude: 41.79,
      longitude: 21.95,
      status: 'VERIFIED',
      upvotesCount: 30,
      commentsCount: 9,
      savesCount: 4,
      sharesCount: 2,
      reports: [
        {
          title: 'Far High',
          description: 'Far High',
          mediaUrls: [] as string[],
          category: 'illegal',
          createdAt: new Date('2026-03-27T08:00:00.000Z'),
          reportNumber: 'R-2',
        },
      ],
      votes: [],
      saves: [],
      _count: { reports: 1 },
    };
    const feedScore = jest.fn((input: any) => input.upvotesCount + input.commentsCount * 2);
    const prismaMock = {
      site: {
        findMany: jest.fn(async () => [siteNear, siteFarHighQuality]),
      },
    } as any;
    const service = new SitesService(
      prismaMock,
      { log: jest.fn() } as any,
      { signUrls: jest.fn(async (v: string[]) => v) } as any,
      { emitSiteCreated: jest.fn(), emitSiteUpdated: jest.fn() } as any,
      {
        score: feedScore,
        scoreDetailed: jest.fn((input: any) => ({
          score: feedScore(input),
          reasonCodes: ['test'],
          components: {},
        })),
      } as any,
      { ensureSiteExists: jest.fn(async () => undefined) } as any,
    );

    const result = await service.findAll({
      lat: 41.6086,
      lng: 21.7453,
      radiusKm: 50,
      page: 1,
      limit: 20,
      sort: 'hybrid',
    } as any);

    expect(result.data[0].id).toBe('site_far_high');
    expect(feedScore).toHaveBeenCalledWith(
      expect.objectContaining({
        distanceKm: expect.any(Number),
        radiusKm: 50,
        reportCount: 1,
      }),
    );
  });

  it('keeps hybrid ordering deterministic when ranking ties', async () => {
    const baseCreatedAt = new Date('2026-03-27T08:00:00.000Z');
    const s1 = {
      id: 'site_a',
      createdAt: baseCreatedAt,
      latitude: 41.61,
      longitude: 21.75,
      status: 'REPORTED',
      upvotesCount: 0,
      commentsCount: 0,
      savesCount: 0,
      sharesCount: 0,
      reports: [
        {
          title: 'A',
          description: 'A',
          mediaUrls: [] as string[],
          category: 'illegal',
          createdAt: baseCreatedAt,
          reportNumber: 'R-3',
        },
      ],
      votes: [],
      saves: [],
      _count: { reports: 1 },
    };
    const s2 = {
      ...s1,
      id: 'site_b',
      reports: [{ ...s1.reports[0], title: 'B' }],
    };
    const prismaMock = {
      site: {
        findMany: jest.fn(async () => [s1, s2]),
      },
    } as any;
    const service = new SitesService(
      prismaMock,
      { log: jest.fn() } as any,
      { signUrls: jest.fn(async (v: string[]) => v) } as any,
      { emitSiteCreated: jest.fn(), emitSiteUpdated: jest.fn() } as any,
      {
        score: jest.fn(() => 1),
        scoreDetailed: jest.fn(() => ({ score: 1, reasonCodes: ['test'], components: {} })),
      } as any,
      { ensureSiteExists: jest.fn(async () => undefined) } as any,
    );

    const first = await service.findAll({ page: 1, limit: 20, sort: 'hybrid' } as any);
    const second = await service.findAll({ page: 1, limit: 20, sort: 'hybrid' } as any);

    expect(first.data.map((s: any) => s.id)).toEqual(['site_b', 'site_a']);
    expect(second.data.map((s: any) => s.id)).toEqual(['site_b', 'site_a']);
  });

  it('returns recent-first order when mode is latest', async () => {
    const older = {
      id: 'site_old',
      createdAt: new Date('2026-03-25T08:00:00.000Z'),
      latitude: 41.61,
      longitude: 21.75,
      status: 'REPORTED',
      upvotesCount: 100,
      commentsCount: 40,
      savesCount: 10,
      sharesCount: 8,
      reports: [
        {
          title: 'Old',
          description: 'Old',
          mediaUrls: [] as string[],
          category: 'illegal_waste',
          createdAt: new Date('2026-03-25T08:00:00.000Z'),
          reportNumber: 'R-11',
        },
      ],
      votes: [],
      saves: [],
      _count: { reports: 1 },
    };
    const newer = {
      ...older,
      id: 'site_new',
      createdAt: new Date('2026-03-27T08:00:00.000Z'),
      reports: [{ ...older.reports[0], title: 'New', createdAt: new Date('2026-03-27T08:00:00.000Z') }],
    };
    const prismaMock = {
      site: {
        findMany: jest.fn(async () => [older, newer]),
      },
    } as any;
    const service = buildService(prismaMock);
    const result = await service.findAll({
      page: 1,
      limit: 20,
      sort: 'hybrid',
      mode: 'latest',
      explain: true,
    } as any);
    expect(result.data[0].id).toBe('site_new');
    expect(result.data[0].rankingReasons).toContain('latest_mode');
  });
});
