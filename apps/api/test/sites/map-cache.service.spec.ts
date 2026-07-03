/// <reference types="jest" />

jest.mock('../../src/config/map.config', () => ({
  loadMapConfig: () => require('../helpers/mock-map-config').mockMapConfigNoRedis(),
}));

import { MapCacheService } from '../../src/sites/map/map-cache.service';
import type { MapResponse } from '../../src/sites/map/map-types';

describe('MapCacheService', () => {
  let service: MapCacheService;

  afterEach(async () => {
    await service?.onModuleDestroy();
  });

  it('does not flush entire memory cache on unknown site targeted invalidate', async () => {
    service = new MapCacheService();
    await service.set('k:1', {
      data: [{ id: 'site_1' } as MapResponse['data'][number]],
      meta: {
        signedMediaExpiresAt: new Date().toISOString(),
        serverTime: new Date().toISOString(),
        queryMode: 'radius',
        dataVersion: 'v1',
      },
    });
    await service.invalidate('site_update', 'site_unknown');
    expect(service.getFromMemory('k:1')).not.toBeNull();
  });
});
