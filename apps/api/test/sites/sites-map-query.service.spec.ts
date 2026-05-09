import { SitesMapQueryService } from '../../src/sites/sites-map-query.service';
import { MapCacheService } from '../../src/sites/map/map-cache.service';
import { MapObservabilityService } from '../../src/sites/map/map-observability.service';
import { MapQueryValidatorService } from '../../src/sites/map/map-query-validator.service';
import { MapResponseProjectorService } from '../../src/sites/map/map-response-projector.service';
import { MapSiteRepositoryService } from '../../src/sites/map/map-site-repository.service';

function makeMapService(input?: {
  validateQuery?: jest.Mock;
  memoryCache?: any;
  redisCache?: any;
  findSites?: jest.Mock;
  projected?: any;
}) {
  const validator = {
    validateQuery: input?.validateQuery ?? jest.fn(),
  } as unknown as MapQueryValidatorService;
  const cache = {
    buildCacheKey: jest.fn(() => 'cache-key'),
    getFromMemory: jest.fn(() => input?.memoryCache ?? null),
    getFromRedis: jest.fn(async () => input?.redisCache ?? null),
    set: jest.fn(async () => undefined),
    invalidate: jest.fn(async () => undefined),
  } as unknown as MapCacheService;
  const metrics = {
    recordRequest: jest.fn(),
    recordZoomTier: jest.fn(),
  } as unknown as MapObservabilityService;
  const repository = {
    findSites:
      input?.findSites ??
      jest.fn(async () => ({
        rows: [],
        usedViewportBbox: false,
        usedFallback: false,
      })),
    findClusters: jest.fn(),
    findHeatmap: jest.fn(),
    resolveDataVersion: jest.fn(async () => '0:0'),
  } as unknown as MapSiteRepositoryService;
  const projector = {
    buildResponse:
      jest.fn(async () => input?.projected ?? { data: [], meta: { signedMediaExpiresAt: '', serverTime: '', queryMode: 'radius', dataVersion: 'v1' } }),
  } as unknown as MapResponseProjectorService;
  return {
    service: new SitesMapQueryService(validator, cache, metrics, repository, projector),
    validator,
    cache,
    metrics,
    repository,
    projector,
  };
}

describe('SitesMapQueryService', () => {
  it('delegates query validation before map fetch', async () => {
    const validateQuery = jest.fn();
    const { service } = makeMapService({
      validateQuery,
      projected: {
        data: [],
        meta: {
          signedMediaExpiresAt: '2026-03-27T10:00:00.000Z',
          serverTime: '2026-03-27T10:00:00.000Z',
          queryMode: 'radius',
          dataVersion: 'v1',
        },
      },
    });
    await service.findAllForMap({ lat: 41.6, lng: 21.7, radiusKm: 20, limit: 120 } as any);
    expect(validateQuery).toHaveBeenCalled();
  });

  it('returns memory cache hit when available', async () => {
    const cached = {
      data: [{ id: 'site_1' }],
      meta: {
        signedMediaExpiresAt: '2026-03-27T10:00:00.000Z',
        serverTime: '2026-03-27T10:00:00.000Z',
        queryMode: 'radius',
        dataVersion: 'v1',
      },
    };
    const { service, repository } = makeMapService({ memoryCache: cached });
    const out = await service.findAllForMap({ lat: 41.6, lng: 21.7, radiusKm: 10, limit: 200 } as any);
    expect(out).toEqual(cached);
    expect((repository.findSites as jest.Mock).mock.calls.length).toBe(0);
  });

  it('loads from repository and projector when cache miss', async () => {
    const findSites = jest.fn(async () => ({
      rows: [{ id: 'site_2' }],
      usedViewportBbox: true,
      usedFallback: false,
    }));
    const projected = {
      data: [{ id: 'site_2' }],
      meta: {
        signedMediaExpiresAt: '2026-03-27T10:00:00.000Z',
        serverTime: '2026-03-27T10:00:00.000Z',
        queryMode: 'viewport',
        dataVersion: 'v2',
      },
    };
    const { service, projector } = makeMapService({ findSites, projected });
    const out = await service.findAllForMap({ lat: 41.6, lng: 21.7, radiusKm: 10, limit: 200 } as any);
    expect(findSites).toHaveBeenCalled();
    expect(projector.buildResponse).toHaveBeenCalled();
    expect(out).toEqual(projected);
  });

  it('keeps includeArchived in query semantics for repository/cache key', async () => {
    const findSites = jest.fn(async () => ({
      rows: [],
      usedViewportBbox: true,
      usedFallback: false,
    }));
    const { service, cache } = makeMapService({ findSites });
    await service.findAllForMap({
      lat: 41.6,
      lng: 21.7,
      radiusKm: 10,
      limit: 120,
      includeArchived: true,
    } as any);
    expect(findSites).toHaveBeenCalledWith(expect.objectContaining({ includeArchived: true }), expect.any(Number));
    expect(cache.buildCacheKey).toHaveBeenCalledWith(expect.arrayContaining(['1']));
  });

  it('findClustersForMap validates and delegates with zoom default', async () => {
    const { service, repository, validator } = makeMapService();
    (repository.findClusters as jest.Mock).mockResolvedValueOnce([
      { clusterKey: '1:1', latitude: 41.6, longitude: 21.7, count: 3, siteIds: ['s1'] },
    ]);
    const result = await service.findClustersForMap({
      lat: 41.6,
      lng: 21.7,
      radiusKm: 20,
      limit: 100,
    } as any);
    expect(validator.validateQuery).toHaveBeenCalled();
    expect(repository.findClusters).toHaveBeenCalledWith(expect.any(Object), 11);
    expect(result.data[0].clusterKey).toBe('1:1');
  });

  it('findHeatmapForMap validates and delegates with explicit zoom', async () => {
    const { service, repository, validator } = makeMapService();
    (repository.findHeatmap as jest.Mock).mockResolvedValueOnce([
      { cellKey: '1:1', latitude: 41.6, longitude: 21.7, intensity: 7 },
    ]);
    const result = await service.findHeatmapForMap({
      lat: 41.6,
      lng: 21.7,
      radiusKm: 20,
      zoom: 8,
      limit: 100,
    } as any);
    expect(validator.validateQuery).toHaveBeenCalled();
    expect(repository.findHeatmap).toHaveBeenCalledWith(expect.any(Object), 8);
    expect(result.data[0].intensity).toBe(7);
  });
});
