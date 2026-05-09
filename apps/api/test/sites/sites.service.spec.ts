import { SiteCommentsService } from '../../src/sites/site-comments.service';
import { SitesAdminService } from '../../src/sites/sites-admin.service';
import { SitesDetailService } from '../../src/sites/sites-detail.service';
import { SitesFeedService } from '../../src/sites/sites-feed.service';
import { SitesMapQueryService } from '../../src/sites/sites-map-query.service';
import { SitesMediaService } from '../../src/sites/sites-media.service';
import { SitesService } from '../../src/sites/sites.service';

function makeSitesService(
  prisma: any,
  options?: {
    feedRanking?: any;
    reportsUpload?: any;
    siteEngagement?: any;
  },
) {
  const siteEngagement =
    options?.siteEngagement ?? ({ ensureSiteExists: jest.fn(async () => undefined) } as any);
  const feedRanking =
    options?.feedRanking ??
    ({
      score: jest.fn(() => 0),
      scoreDetailed: jest.fn(() => ({ score: 0, reasonCodes: ['test'], components: {} })),
    } as any);
  const reportsUpload =
    options?.reportsUpload ?? ({ signUrls: jest.fn(async (v: string[]) => v) } as any);
  const audit = { log: jest.fn() } as any;
  const mapValidator = { validateQuery: jest.fn() } as any;
  const mapCache = {
    buildCacheKey: jest.fn(() => 'test-key'),
    getFromMemory: jest.fn(() => null),
    getFromRedis: jest.fn(async () => null),
    set: jest.fn(async () => undefined),
    invalidate: jest.fn(async () => undefined),
  } as any;
  const mapMetrics = { recordRequest: jest.fn() } as any;
  const mapRepository = {
    findSites: jest.fn(async () => ({ rows: [], usedPostgisExactGeo: false, usedFallback: false })),
    findClusters: jest.fn(async () => []),
    findHeatmap: jest.fn(async () => []),
  } as any;
  const mapProjector = {
    buildResponse: jest.fn(async () => ({ data: [], meta: { dataVersion: '0', queryMode: 'radius' } })),
  } as any;
  const sitesMapQuery = new SitesMapQueryService(
    mapValidator,
    mapCache,
    mapMetrics,
    mapRepository,
    mapProjector,
  );
  const feedV2 = {
    resolveVariant: jest.fn(async () => 'v1' as const),
    rerankRows: jest.fn(async (rows: unknown[]) => rows),
  } as any;
  const userStateRepo = {} as any;
  const sitesFeed = new SitesFeedService(
    prisma,
    audit,
    reportsUpload,
    feedRanking,
    siteEngagement,
    feedV2,
    userStateRepo,
  );
  const siteDetailRepository = {
    findByIdWithRelations: jest.fn(async (siteId: string, _reportsTake: number, _eventsTake: number) => {
      if (prisma.site?.findUnique) {
        return prisma.site.findUnique({ where: { id: siteId } });
      }
      return null;
    }),
    countReports: jest.fn(async () => 0),
    countEvents: jest.fn(async () => 0),
    findVoteBySiteAndUser: jest.fn(async () => null),
    findSaveBySiteAndUser: jest.fn(async () => null),
  } as any;
  const sitesDetail = new SitesDetailService(siteDetailRepository, reportsUpload);
  const sitesMedia = new SitesMediaService(prisma, reportsUpload, siteEngagement);
  const siteEvents = { emitSiteCreated: jest.fn(), emitSiteUpdated: jest.fn() } as any;
  const sitesAdmin = new SitesAdminService(prisma, audit, siteEvents, sitesMapQuery, sitesFeed);
  const siteUpvotesRepository = {} as any;
  const sitesSearch = { searchMapSites: jest.fn() } as any;
  const mapMvtTiles = { getTileOrThrow: jest.fn() } as any;
  return new SitesService(
    prisma,
    reportsUpload,
    siteEngagement,
    new SiteCommentsService(prisma, siteEngagement, reportsUpload),
    { emit: jest.fn() } as any,
    sitesMapQuery,
    sitesFeed,
    sitesDetail,
    sitesMedia,
    sitesAdmin,
    siteUpvotesRepository,
    sitesSearch,
    mapMvtTiles,
  );
}

describe('SitesService', () => {
  const baseUser = { userId: 'user_1' } as any;

  const buildService = (prismaMock: any, ensureSiteExists?: jest.Mock) =>
    makeSitesService(prismaMock, {
      siteEngagement: {
        ensureSiteExists: ensureSiteExists ?? jest.fn(async () => undefined),
      } as any,
    });

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
        count: jest.fn(async () => 2),
      },
    } as any;
    const service = makeSitesService(prismaMock, {
      feedRanking: {
        score: feedScore,
        scoreDetailed: jest.fn((input: any) => ({
          score: feedScore(input),
          reasonCodes: ['test'],
          components: {},
        })),
      } as any,
    });

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
        count: jest.fn(async () => 2),
      },
    } as any;
    const service = makeSitesService(prismaMock, {
      feedRanking: {
        score: jest.fn(() => 1),
        scoreDetailed: jest.fn(() => ({ score: 1, reasonCodes: ['test'], components: {} })),
      } as any,
    });

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
        count: jest.fn(async () => 2),
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

  it('findOne includes coReporterNames aggregated from report co-reporter rows', async () => {
    const reportedAtEarly = new Date('2026-04-01T10:00:00.000Z');
    const reportedAtLate = new Date('2026-04-03T10:00:00.000Z');
    const prismaMock = {
      site: {
        findUnique: jest.fn(async () => ({
          id: 'site_corep',
          latitude: 41.6,
          longitude: 21.7,
          address: null,
          description: 'Site',
          status: 'REPORTED',
          createdAt: new Date('2026-03-01'),
          updatedAt: new Date('2026-03-01'),
          upvotesCount: 0,
          commentsCount: 0,
          savesCount: 0,
          sharesCount: 0,
          reports: [
            {
              id: 'rep_primary',
              createdAt: new Date('2026-04-01'),
              reportNumber: 'R-100',
              siteId: 'site_corep',
              reporterId: 'user_primary',
              title: 'Primary',
              description: null,
              mediaUrls: [] as string[],
              category: 'illegal',
              severity: null,
              cleanupEffort: null,
              status: 'APPROVED',
              moderatedAt: null,
              moderationReason: null,
              moderatedById: null,
              potentialDuplicateOfId: null,
              mergedDuplicateChildCount: 0,
              reporter: {
                firstName: 'Pri',
                lastName: 'Mary',
                avatarObjectKey: null,
              },
              coReporters: [
                {
                  id: 'cr1',
                  createdAt: reportedAtEarly,
                  reportedAt: reportedAtLate,
                  reportId: 'rep_primary',
                  userId: 'user_ben',
                  user: { firstName: 'Ben', lastName: 'Co', avatarObjectKey: null },
                },
                {
                  id: 'cr2',
                  createdAt: reportedAtEarly,
                  reportedAt: reportedAtEarly,
                  reportId: 'rep_primary',
                  userId: 'user_ann',
                  user: { firstName: '', lastName: '', avatarObjectKey: null },
                },
              ],
            },
          ],
          events: [] as unknown[],
        })),
      },
      siteVote: { findUnique: jest.fn(async () => null) },
      siteSave: { findUnique: jest.fn(async () => null) },
    } as any;

    const service = makeSitesService(prismaMock, {
      reportsUpload: {
        signUrls: jest.fn(async (urls: string[]) => urls),
        signPrivateObjectKey: jest.fn(async () => null),
      } as any,
    });

    const out = await service.findOne('site_corep');
    expect(out.coReporterNames).toEqual(['Anonymous', 'Ben Co']);
    expect(out.coReporterSummaries).toHaveLength(2);
    expect(out.coReporterSummaries.map((s) => s.name)).toEqual(['Anonymous', 'Ben Co']);
    expect(out.coReporterSummaries.map((s) => s.userId).sort()).toEqual(['user_ann', 'user_ben'].sort());
    expect(out.mergedDuplicateChildCountTotal).toBe(0);
  });
});
