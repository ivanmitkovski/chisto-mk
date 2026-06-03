/// <reference types="jest" />

jest.mock('../../../../src/config/feature-flags', () => ({
  loadFeatureFlags: jest.fn(),
}));

import { NotFoundException } from '@nestjs/common';
import { loadFeatureFlags } from '../../../../src/config/feature-flags';
import { MapOfflineRegionsService } from '../../../../src/sites/map/offline/map-offline-regions.service';

const loadFeatureFlagsMock = loadFeatureFlags as jest.MockedFunction<typeof loadFeatureFlags>;

describe('MapOfflineRegionsService', () => {
  const OLD_ENV = process.env;

  beforeEach(() => {
    jest.resetModules();
    process.env = { ...OLD_ENV };
    delete process.env.MAP_OFFLINE_REGIONS_MANIFEST_JSON;
  });

  afterAll(() => {
    process.env = OLD_ENV;
  });

  it('throws NotFound when feature flag is disabled', async () => {
    loadFeatureFlagsMock.mockReturnValue({
      mapEtagEnabled: true,
      mapSseEnabled: true,
      mapCacheEnabled: true,
      mapUseProjection: false,
      mapPostgisEnabled: false,
      mapTileFormatVector: false,
      mapSearchTypesense: false,
      mapAdminTimeMachine: false,
      mapOfflineRegions: false,
    });
    const s3 = { enabled: true } as never;
    const svc = new MapOfflineRegionsService(s3);
    await expect(svc.getManifest()).rejects.toBeInstanceOf(NotFoundException);
  });

  it('returns manifest from inline JSON when enabled', async () => {
    loadFeatureFlagsMock.mockReturnValue({
      mapEtagEnabled: true,
      mapSseEnabled: true,
      mapCacheEnabled: true,
      mapUseProjection: false,
      mapPostgisEnabled: false,
      mapTileFormatVector: false,
      mapSearchTypesense: false,
      mapAdminTimeMachine: false,
      mapOfflineRegions: true,
    });
    process.env.MAP_OFFLINE_REGIONS_MANIFEST_JSON = JSON.stringify([
      {
        id: 'mk-demo',
        label: 'Demo region',
        version: 2,
        checksumSha256: 'deadbeef',
        bounds: { minLat: 41, maxLat: 42, minLng: 20, maxLng: 22 },
        s3Key: 'map-offline/regions/mk-demo-v2.mbtiles',
        updatedAt: '2026-06-01T00:00:00.000Z',
      },
    ]);

    const s3 = { enabled: false, getClientOrNull: () => null, bucket: null } as never;
    const svc = new MapOfflineRegionsService(s3);
    const manifest = await svc.getManifest();

    expect(manifest.regions).toHaveLength(1);
    expect(manifest.regions[0].id).toBe('mk-demo');
    expect(manifest.regions[0].version).toBe(2);
    expect(manifest.regions[0].checksumSha256).toBe('deadbeef');
  });
});
