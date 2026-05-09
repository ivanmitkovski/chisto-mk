/// <reference types="jest" />

import { MapSiteRepositoryService } from '../../src/sites/map/map-site-repository.service';
import { MapQueryValidatorService } from '../../src/sites/map/map-query-validator.service';
import { ListSitesMapQueryDto } from '../../src/sites/dto/list-sites-map-query.dto';

jest.mock('../../src/config/feature-flags', () => ({
  loadFeatureFlags: jest.fn(() => ({
    mapUseProjection: true,
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

const mockedLoadFeatureFlags = jest.requireMock('../../src/config/feature-flags')
  .loadFeatureFlags as jest.Mock;

/** Expands Prisma.sql fragments embedded in a tagged-template `$queryRaw` call. */
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
  const strings = call[0] as TemplateStringsArray;
  let out = '';
  for (let i = 0; i < strings.raw.length; i++) {
    out += strings.raw[i];
    if (i + 1 < call.length) {
      out += flattenSqlFragment(call[i + 1]);
    }
  }
  return out;
}

describe('MapSiteRepositoryService', () => {
  beforeEach(() => {
    mockedLoadFeatureFlags.mockReset();
    mockedLoadFeatureFlags.mockReturnValue({
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
  });

  it('includes isHot filter for projection findSites', async () => {
    const prisma = {
      $queryRaw: jest.fn().mockResolvedValue([]),
      site: { findMany: jest.fn() },
    };
    const validator = {
      hasViewportBounds: jest.fn().mockReturnValue(false),
    } as unknown as MapQueryValidatorService;

    const svc = new MapSiteRepositoryService(prisma as never, validator);
    const query = { lat: 41.9, lng: 21.4, radiusKm: 50 } as ListSitesMapQueryDto;
    await svc.findSites(query, 10);

    expect(prisma.$queryRaw).toHaveBeenCalled();
    const text = sqlTextFromQueryRawCall(prisma.$queryRaw.mock.calls[0] as unknown[]);
    expect(text).toContain('"isHot" = true');
  });

  it('includes isHot filter for projection resolveDataVersion', async () => {
    const prisma = {
      $queryRaw: jest.fn().mockResolvedValue([{ count: 0, latestUpdatedAt: null }]),
      site: { findMany: jest.fn() },
    };
    const validator = {
      hasViewportBounds: jest.fn().mockReturnValue(false),
    } as unknown as MapQueryValidatorService;

    const svc = new MapSiteRepositoryService(prisma as never, validator);
    const query = { lat: 41.9, lng: 21.4, radiusKm: 50 } as ListSitesMapQueryDto;
    await svc.resolveDataVersion(query);

    const text = sqlTextFromQueryRawCall(prisma.$queryRaw.mock.calls[0] as unknown[]);
    expect(text).toContain('"isHot" = true');
  });

  it('uses ST_DWithin against geo when mapPostgisEnabled is true (radius query)', async () => {
    mockedLoadFeatureFlags.mockReturnValue({
      mapUseProjection: true,
      mapEtagEnabled: true,
      mapSseEnabled: true,
      mapCacheEnabled: true,
      mapPostgisEnabled: true,
      mapTileFormatVector: false,
      mapSearchTypesense: false,
      mapAdminTimeMachine: false,
      mapOfflineRegions: false,
    });
    const prisma = {
      $queryRaw: jest.fn().mockResolvedValue([]),
      site: { findMany: jest.fn() },
    };
    const validator = {
      hasViewportBounds: jest.fn().mockReturnValue(false),
    } as unknown as MapQueryValidatorService;

    const svc = new MapSiteRepositoryService(prisma as never, validator);
    const query = { lat: 41.9, lng: 21.4, radiusKm: 50 } as ListSitesMapQueryDto;
    await svc.findSites(query, 10);

    const text = sqlTextFromQueryRawCall(prisma.$queryRaw.mock.calls[0] as unknown[]);
    expect(text).toContain('ST_DWithin(');
    expect(text).toContain('"geo"');
  });
});
