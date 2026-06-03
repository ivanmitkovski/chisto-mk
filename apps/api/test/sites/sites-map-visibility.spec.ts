import { MapSiteRepositoryAggregatesService } from '../../src/sites/map/map-site-repository-aggregates.service';
import { MapSiteRepositoryService } from '../../src/sites/map/map-site-repository.service';
import { MapSiteRepositorySitesService } from '../../src/sites/map/map-site-repository-sites.service';
import { MapQueryValidatorService } from '../../src/sites/map/map-query-validator.service';
import { ListSitesMapQueryDto } from '../../src/sites/dto/list-sites-map-query.dto';

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

describe('MapSiteRepositoryService site visibility', () => {
  it('uses status-based Prisma filter for anonymous canonical fallback', async () => {
    const findMany = jest.fn(async () => []);
    const prisma = {
      $queryRaw: jest.fn(),
      site: { findMany },
    };
    const validator = {
      hasViewportBounds: jest.fn().mockReturnValue(false),
    } as unknown as MapQueryValidatorService;

    const sitesSvc = new MapSiteRepositorySitesService(prisma as never, validator);
    const aggSvc = new MapSiteRepositoryAggregatesService(prisma as never, validator);
    const svc = new MapSiteRepositoryService(sitesSvc, aggSvc);
    const query = { lat: 41.9, lng: 21.4, radiusKm: 50 } as ListSitesMapQueryDto;

    await svc.findSites(query, 10);

    expect(findMany).toHaveBeenCalled();
    const where = (findMany.mock.calls[0] as any[])[0].where;
    expect(where).toEqual(
      expect.objectContaining({
        status: { not: 'REPORTED' },
      }),
    );
  });

  it('includes reporter visibility for authenticated canonical fallback', async () => {
    const findMany = jest.fn(async () => []);
    const prisma = {
      $queryRaw: jest.fn(),
      site: { findMany },
    };
    const validator = {
      hasViewportBounds: jest.fn().mockReturnValue(false),
    } as unknown as MapQueryValidatorService;

    const sitesSvc = new MapSiteRepositorySitesService(prisma as never, validator);
    const aggSvc = new MapSiteRepositoryAggregatesService(prisma as never, validator);
    const svc = new MapSiteRepositoryService(sitesSvc, aggSvc);
    const query = { lat: 41.9, lng: 21.4, radiusKm: 50 } as ListSitesMapQueryDto;

    await svc.findSites(query, 10, 'viewer-1');

    const where = (findMany.mock.calls[0] as any[])[0].where;
    expect(where.OR).toEqual(
      expect.arrayContaining([
        { status: { not: 'REPORTED' } },
        { reports: { some: { reporterId: 'viewer-1' } } },
      ]),
    );
  });
});
