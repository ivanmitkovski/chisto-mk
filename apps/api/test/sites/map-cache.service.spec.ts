/// <reference types="jest" />

import { MapCacheService } from '../../src/sites/map/map-cache.service';

describe('MapCacheService', () => {
  it('does not flush entire memory cache on unknown site targeted invalidate', async () => {
    const service = new MapCacheService() as unknown as {
      set: (cacheKey: string, value: any) => Promise<void>;
      invalidate: (reason: string, siteId?: string) => Promise<void>;
      getFromMemory: (cacheKey: string) => any;
    };
    await service.set('k:1', {
      data: [{ id: 'site_1' }],
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
