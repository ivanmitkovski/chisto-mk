import { FeedRankingService } from '../../src/sites/services/feed-ranking.service';
import { SiteFeedGeoScope } from '../../src/sites/dto/list-sites-query.dto';
import { SitesFeedCandidatesService } from '../../src/sites/services/sites-feed-candidates.service';
import { SitesFeedEnrichmentService } from '../../src/sites/services/sites-feed-enrichment.service';
import { SitesFeedQueryService } from '../../src/sites/services/sites-feed-query.service';
import { SitesFeedService } from '../../src/sites/services/sites-feed.service';

function makeSiteRow(
  id: string,
  lat: number,
  lng: number,
  upvotesCount: number,
  commentsCount: number,
) {
  return {
    id,
    createdAt: new Date('2026-03-27T08:00:00.000Z'),
    latitude: lat,
    longitude: lng,
    status: 'VERIFIED',
    upvotesCount,
    commentsCount,
    savesCount: 0,
    sharesCount: upvotesCount > 10 ? 2 : 0,
    reports: [
      {
        title: id,
        description: id,
        mediaUrls: [] as string[],
        category: 'illegal',
        createdAt: new Date('2026-03-27T08:00:00.000Z'),
        reportNumber: `R-${id}`,
      },
    ],
    votes: [],
    saves: [],
    _count: { reports: 1 },
  };
}

function emptyGroupBy() {
  return jest.fn().mockResolvedValue([]);
}

function withVelocityPrisma(base: Record<string, unknown>) {
  return {
    ...base,
    siteVote: { groupBy: emptyGroupBy() },
    siteSave: { groupBy: emptyGroupBy() },
    siteShareEvent: { groupBy: emptyGroupBy() },
  };
}

function makeFeedStack(prisma: any, feedRanking?: FeedRankingService) {
  const reportsUpload = { signUrls: jest.fn(async (v: string[]) => v) } as any;
  const ranking = feedRanking ?? new FeedRankingService();
  const feedV2 = {
    resolveVariant: jest.fn(async () => 'v1' as const),
    rerankRows: jest.fn(async (rows: unknown[]) => rows),
  } as any;
  const feedCache = {
    buildFeedCacheKey: jest.fn(() => 'feed-cache-key'),
    get: jest.fn(() => undefined),
    set: jest.fn(),
    invalidate: jest.fn(),
  } as any;
  const feedPreferences = {
    applyUserPreferences: jest.fn((rows: unknown[]) => rows),
    setVariantMemo: jest.fn(),
    getFeedVariantForUser: jest.fn(() => 'v1'),
  } as any;
  const feedTracking = {
    trackFeedEvent: jest.fn(),
    submitFeedFeedback: jest.fn(),
  } as any;
  const feedCandidates = new SitesFeedCandidatesService(prisma);
  const siteCommentsCount = {
    countVisibleBatch: jest.fn(async () => new Map<string, number>()),
  };
  const feedEnrichment = new SitesFeedEnrichmentService(
    prisma,
    reportsUpload,
    ranking,
    feedV2,
    feedCache,
    feedPreferences,
    siteCommentsCount as never,
  );
  const feedQuery = new SitesFeedQueryService(feedCandidates, feedEnrichment);
  const sitesFeed = new SitesFeedService(feedQuery, feedCache, feedPreferences, feedTracking);
  return {
    findAll: (query: any, user?: any) => sitesFeed.findAll(query, user),
    feedCandidates,
    prisma,
  };
}

describe('Sites feed discovery scope', () => {
  const originalEnv = process.env.FEED_DISCOVERY_ENABLED;
  const nearSite = makeSiteRow('site_near', 41.61, 21.75, 2, 0);
  const farSite = makeSiteRow('site_far_high', 42.2, 22.4, 30, 9);

  afterEach(() => {
    if (originalEnv === undefined) {
      delete process.env.FEED_DISCOVERY_ENABLED;
    } else {
      process.env.FEED_DISCOVERY_ENABLED = originalEnv;
    }
  });

  it('local scope excludes far sites beyond radiusKm', async () => {
    const findMany = jest.fn(async (args: any) => {
      if (args.where?.latitude) {
        return [nearSite];
      }
      return [nearSite, farSite];
    });
    const prismaMock = withVelocityPrisma({
      site: { findMany, count: jest.fn(async () => 1) },
    }) as any;
    const { findAll } = makeFeedStack(prismaMock);

    const result = await findAll({
      lat: 41.6086,
      lng: 21.7453,
      radiusKm: 25,
      page: 1,
      limit: 20,
      sort: 'hybrid',
      scope: SiteFeedGeoScope.LOCAL,
    } as any);

    expect(result.data.map((row) => row.id)).toEqual(['site_near']);
    expect(findMany).toHaveBeenCalledTimes(1);
  });

  it('discovery scope returns far sites without hard radius cutoff', async () => {
    const findMany = jest.fn(async (args: any) => {
      if (args.orderBy?.[0]?.sharesCount !== undefined) {
        return [farSite];
      }
      if (args.where?.latitude) {
        return [nearSite];
      }
      return [farSite];
    });
    const prismaMock = withVelocityPrisma({
      site: { findMany, count: jest.fn(async () => 2) },
    }) as any;
    const { findAll } = makeFeedStack(prismaMock, new FeedRankingService());

    const result = await findAll({
      lat: 41.6086,
      lng: 21.7453,
      radiusKm: 25,
      page: 1,
      limit: 20,
      sort: 'hybrid',
      scope: SiteFeedGeoScope.DISCOVERY,
    } as any);

    expect(result.data.map((row) => row.id)).toContain('site_far_high');
    expect(findMany.mock.calls.length).toBeGreaterThanOrEqual(2);
  });

  it('discovery ranks far high-engagement above near low-engagement', async () => {
    const findMany = jest.fn(async () => [nearSite, farSite]);
    const prismaMock = withVelocityPrisma({
      site: { findMany, count: jest.fn(async () => 2) },
    }) as any;
    const { findAll } = makeFeedStack(prismaMock, new FeedRankingService());

    const result = await findAll({
      lat: 41.6086,
      lng: 21.7453,
      radiusKm: 150,
      page: 1,
      limit: 20,
      sort: 'hybrid',
      scope: SiteFeedGeoScope.DISCOVERY,
    } as any);

    expect(result.data[0]?.id).toBe('site_far_high');
  });

  it('FEED_DISCOVERY_ENABLED=false forces local candidate path', async () => {
    process.env.FEED_DISCOVERY_ENABLED = 'false';
    const findMany = jest.fn(async (args: any) => {
      if (args.where?.latitude) {
        return [nearSite];
      }
      return [nearSite, farSite];
    });
    const prismaMock = withVelocityPrisma({
      site: { findMany, count: jest.fn(async () => 1) },
    }) as any;
    const { findAll } = makeFeedStack(prismaMock);

    const result = await findAll({
      lat: 41.6086,
      lng: 21.7453,
      radiusKm: 25,
      page: 1,
      limit: 20,
      sort: 'hybrid',
      scope: SiteFeedGeoScope.DISCOVERY,
    } as any);

    expect(result.data.map((row) => row.id)).toEqual(['site_near']);
    expect(findMany).toHaveBeenCalledTimes(1);
  });
});

describe('SitesFeedCandidatesService discovery merge', () => {
  it('merges fresh, trending, and nearby retrievers with dedupe', async () => {
    const freshSite = makeSiteRow('fresh', 41.5, 21.5, 1, 0);
    const trendingSite = makeSiteRow('trending', 41.6, 21.6, 20, 4);
    const nearbySite = makeSiteRow('nearby', 41.608, 21.745, 3, 1);
    const findMany = jest.fn(async (args: any) => {
      if (args.orderBy?.[0]?.sharesCount !== undefined) {
        return [trendingSite, nearbySite];
      }
      if (args.where?.latitude) {
        return [nearbySite];
      }
      return [freshSite, nearbySite];
    });
    const prismaMock = withVelocityPrisma({
      site: { findMany },
    }) as any;
    const service = new SitesFeedCandidatesService(prismaMock);

    const bundle = await service.loadCandidateSites(
      {
        lat: 41.6086,
        lng: 21.7453,
        radiusKm: 25,
        page: 1,
        limit: 20,
        sort: 'hybrid',
        scope: SiteFeedGeoScope.DISCOVERY,
      } as any,
      undefined,
    );

    expect(findMany).toHaveBeenCalledTimes(3);
    expect(bundle.sites.map((row) => row.id).sort()).toEqual(
      ['fresh', 'nearby', 'trending'].sort(),
    );
  });
});
