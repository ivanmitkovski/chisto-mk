import { Prisma } from '../../src/prisma-client';
import { MapMvtTilesFallbackService } from '../../src/sites/map/map-mvt-tiles-fallback.service';
import { MapMvtTilesPostgisService } from '../../src/sites/map/map-mvt-tiles-postgis.service';
import { MapSiteRepositoryAggregatesService } from '../../src/sites/map/map-site-repository-aggregates.service';
import { MapSiteRepositoryService } from '../../src/sites/map/map-site-repository.service';
import { MapSiteRepositorySitesService } from '../../src/sites/map/map-site-repository-sites.service';
import { MapQueryValidatorService } from '../../src/sites/map/map-query-validator.service';
import { ListSitesMapQueryDto } from '../../src/sites/dto/list-sites-map-query.dto';
import {
  assertQualifiedSiteIdSql,
  siteVisibilitySql,
} from '../../src/sites/util/site-visibility.helper';

jest.mock('../../src/config/feature-flags', () => ({
  loadFeatureFlags: jest.fn(() => ({
    mapUseProjection: false,
    mapEtagEnabled: true,
    mapSseEnabled: true,
    mapCacheEnabled: true,
    mapPostgisEnabled: false,
    mapTileFormatVector: false,
    mapSearchTypesense: false,
    mapAdminTimeMachine: false,
    mapOfflineRegions: false,
  })),
}));

const { loadFeatureFlags } = jest.requireMock('../../src/config/feature-flags') as {
  loadFeatureFlags: jest.Mock;
};

function flattenSqlFragment(value: unknown): string {
  if (value == null) {
    return '';
  }
  if (typeof value === 'string' || typeof value === 'number' || typeof value === 'boolean') {
    return String(value);
  }
  if (typeof value === 'object' && value !== null && 'strings' in value) {
    const chunk = value as { strings: readonly string[]; values?: readonly unknown[] };
    let out = chunk.strings.join('');
    if (chunk.values?.length) {
      for (const v of chunk.values) {
        out += flattenSqlFragment(v);
      }
    }
    return out;
  }
  return '';
}

function sqlTextFromQueryRawCall(call: unknown[]): string {
  const first = call[0];
  if (first && typeof first === 'object' && 'strings' in first && !Array.isArray(first)) {
    return flattenSqlFragment(first);
  }
  const strings = first as TemplateStringsArray;
  let out = '';
  for (let i = 0; i < strings.raw.length; i++) {
    out += strings.raw[i];
    if (i + 1 < call.length) {
      out += flattenSqlFragment(call[i + 1]);
    }
  }
  return out;
}

function makeRepositoryServices() {
  const prisma = {
    $queryRaw: jest.fn().mockResolvedValue([]),
    site: { findMany: jest.fn().mockResolvedValue([]) },
  };
  const validator = {
    hasViewportBounds: jest.fn().mockReturnValue(false),
  } as unknown as MapQueryValidatorService;
  const sitesSvc = new MapSiteRepositorySitesService(prisma as never, validator);
  const aggSvc = new MapSiteRepositoryAggregatesService(prisma as never, validator);
  const svc = new MapSiteRepositoryService(sitesSvc, aggSvc);
  const query = { lat: 41.9, lng: 21.4, radiusKm: 50 } as ListSitesMapQueryDto;
  return { prisma, svc, query, sitesSvc, aggSvc, validator };
}

describe('siteVisibilitySql helper', () => {
  it('throws when siteIdSql is unqualified', () => {
    expect(() =>
      assertQualifiedSiteIdSql(Prisma.sql`"siteId"`),
    ).toThrow(/table-qualified siteIdSql/);
    expect(() =>
      siteVisibilitySql({
        siteIdSql: Prisma.sql`"siteId"`,
        siteStatusSql: Prisma.sql`"status"`,
        viewerUserId: 'viewer-1',
      }),
    ).toThrow(/table-qualified siteIdSql/);
  });

  it('accepts qualified site id references', () => {
    expect(() =>
      assertQualifiedSiteIdSql(Prisma.sql`"MapSiteProjection"."siteId"`),
    ).not.toThrow();
    expect(() =>
      assertQualifiedSiteIdSql(Prisma.sql`s."id"`),
    ).not.toThrow();
  });

  it('anonymous clause excludes REPORTED only', () => {
    const clause = siteVisibilitySql({
      siteIdSql: Prisma.sql`"MapSiteProjection"."siteId"`,
      siteStatusSql: Prisma.sql`"MapSiteProjection"."status"`,
      viewerUserId: null,
    });
    const text = flattenSqlFragment(clause);
    expect(text).toContain(`<> 'REPORTED'`);
    expect(text).not.toContain('EXISTS');
  });

  it('authenticated clause correlates outer site id in both EXISTS branches', () => {
    const clause = siteVisibilitySql({
      siteIdSql: Prisma.sql`"MapSiteProjection"."siteId"`,
      siteStatusSql: Prisma.sql`"MapSiteProjection"."status"`,
      viewerUserId: 'viewer-1',
    });
    const text = flattenSqlFragment(clause);
    expect(text).toContain('r_vis."siteId" = "MapSiteProjection"."siteId"');
    expect(text).toContain('r_vis."reporterId"');
    expect(text).toContain('cr_vis."userId"');
    expect(text).toContain('viewer-1');
    expect(text).not.toMatch(/r_vis\."siteId"\s*=\s*"siteId"/);
  });
});

describe('MapSiteRepositoryService site visibility', () => {
  beforeEach(() => {
    loadFeatureFlags.mockReset();
    loadFeatureFlags.mockReturnValue({
      mapUseProjection: false,
      mapEtagEnabled: true,
      mapSseEnabled: true,
      mapCacheEnabled: true,
      mapPostgisEnabled: false,
      mapTileFormatVector: false,
      mapSearchTypesense: false,
      mapAdminTimeMachine: false,
      mapOfflineRegions: false,
    });
  });

  it('uses status-based Prisma filter for anonymous canonical fallback', async () => {
    const { prisma, svc, query } = makeRepositoryServices();
    await svc.findSites(query, 10);

    expect(prisma.site.findMany).toHaveBeenCalled();
    const where = (prisma.site.findMany.mock.calls[0] as any[])[0].where;
    expect(where).toEqual(
      expect.objectContaining({
        status: { not: 'REPORTED' },
      }),
    );
  });

  it('includes reporter visibility for authenticated canonical fallback', async () => {
    const { prisma, svc, query } = makeRepositoryServices();
    await svc.findSites(query, 10, 'viewer-1');

    const where = (prisma.site.findMany.mock.calls[0] as any[])[0].where;
    expect(where.OR).toEqual(
      expect.arrayContaining([
        { status: { not: 'REPORTED' } },
        { reports: { some: { reporterId: 'viewer-1' } } },
      ]),
    );
  });

  it('projection findSites uses qualified site id correlation', async () => {
    loadFeatureFlags.mockReturnValue({
      mapUseProjection: true,
      mapEtagEnabled: true,
      mapSseEnabled: true,
      mapCacheEnabled: true,
      mapPostgisEnabled: false,
      mapTileFormatVector: false,
      mapSearchTypesense: false,
      mapAdminTimeMachine: false,
      mapOfflineRegions: false,
    });
    const { prisma, svc, query } = makeRepositoryServices();
    await svc.findSites(query, 10, 'viewer-1');

    const text = sqlTextFromQueryRawCall(prisma.$queryRaw.mock.calls[0] as unknown[]);
    expect(text).toContain('r_vis."siteId" = "MapSiteProjection"."siteId"');
    expect(text).not.toMatch(/r_vis\."siteId"\s*=\s*"siteId"/);
  });

  it('projection resolveDataVersion uses qualified site id correlation', async () => {
    loadFeatureFlags.mockReturnValue({
      mapUseProjection: true,
      mapEtagEnabled: true,
      mapSseEnabled: true,
      mapCacheEnabled: true,
      mapPostgisEnabled: false,
      mapTileFormatVector: false,
      mapSearchTypesense: false,
      mapAdminTimeMachine: false,
      mapOfflineRegions: false,
    });
    const { prisma, svc, query } = makeRepositoryServices();
    prisma.$queryRaw.mockResolvedValue([{ count: 0, latestUpdatedAt: null }]);
    await svc.resolveDataVersion(query, 'viewer-1');

    const text = sqlTextFromQueryRawCall(prisma.$queryRaw.mock.calls[0] as unknown[]);
    expect(text).toContain('r_vis."siteId" = "MapSiteProjection"."siteId"');
  });

  it('canonical aggregates use Site.id correlation', async () => {
    const { prisma, aggSvc, query } = makeRepositoryServices();
    await aggSvc.findClusters(query, 11, 'viewer-1');

    const text = sqlTextFromQueryRawCall(prisma.$queryRaw.mock.calls[0] as unknown[]);
    expect(text).toContain('r_vis."siteId" = "Site"."id"');
  });

  it('projection aggregates use MapSiteProjection.siteId correlation', async () => {
    loadFeatureFlags.mockReturnValue({
      mapUseProjection: true,
      mapEtagEnabled: true,
      mapSseEnabled: true,
      mapCacheEnabled: true,
      mapPostgisEnabled: false,
      mapTileFormatVector: false,
      mapSearchTypesense: false,
      mapAdminTimeMachine: false,
      mapOfflineRegions: false,
    });
    const { prisma, aggSvc, query } = makeRepositoryServices();
    await aggSvc.findHeatmap(query, 11, 'viewer-1');

    const text = sqlTextFromQueryRawCall(prisma.$queryRaw.mock.calls[0] as unknown[]);
    expect(text).toContain('r_vis."siteId" = "MapSiteProjection"."siteId"');
  });
});

describe('Map MVT tile visibility SQL', () => {
  it('postgis tiles use qualified MapSiteProjection site id correlation', async () => {
    const prisma = { $queryRaw: jest.fn().mockResolvedValue([{ mvt: Buffer.from([]), max_updated: null, cnt: 0 }]) };
    const svc = new MapMvtTilesPostgisService(prisma as never);
    await svc.generateTile(13, 4500, 3000, 'viewer-1');

    const text = sqlTextFromQueryRawCall(prisma.$queryRaw.mock.calls[0] as unknown[]);
    expect(text).toContain('r_vis."siteId" = "MapSiteProjection"."siteId"');
  });

  it('fallback tiles use qualified MapSiteProjection site id correlation', async () => {
    const prisma = { $queryRaw: jest.fn().mockResolvedValue([]) };
    const svc = new MapMvtTilesFallbackService(prisma as never);
    await svc.generateTile(13, 4500, 3000, 'viewer-1');

    const text = sqlTextFromQueryRawCall(prisma.$queryRaw.mock.calls[0] as unknown[]);
    expect(text).toContain('r_vis."siteId" = "MapSiteProjection"."siteId"');
  });
});
