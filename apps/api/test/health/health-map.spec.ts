/// <reference types="jest" />

import { HealthController } from '../../src/health/health.controller';

jest.mock('../../src/config/feature-flags', () => ({
  loadFeatureFlags: () => ({
    mapUseProjection: true,
    mapEtagEnabled: true,
    mapSseEnabled: true,
    mapCacheEnabled: true,
    mapPostgisEnabled: false,
    mapTileFormatVector: false,
    mapSearchTypesense: false,
    mapAdminTimeMachine: false,
    mapOfflineRegions: false,
  }),
}));

describe('HealthController mapPipeline', () => {
  it('returns degraded when outbox pending exceeds threshold', async () => {
    const prisma = {
      $queryRaw: jest
        .fn()
        .mockResolvedValueOnce([{ c: 150n }])
        .mockResolvedValueOnce([{ c: 0n }]),
    } as unknown as ConstructorParameters<typeof HealthController>[0];
    const s3 = {} as ConstructorParameters<typeof HealthController>[1];
    const controller = new HealthController(prisma, s3);
    const out = await controller.mapPipeline();
    expect(out.status).toBe('degraded');
    expect(out.alerts.some((a) => a.startsWith('map_outbox_pending_high'))).toBe(true);
    expect(out.outboxPending).toBe(150);
  });

  it('returns ok when counters are healthy', async () => {
    const prisma = {
      $queryRaw: jest
        .fn()
        .mockResolvedValueOnce([{ c: 3n }])
        .mockResolvedValueOnce([{ c: 0n }]),
    } as unknown as ConstructorParameters<typeof HealthController>[0];
    const controller = new HealthController(prisma, {} as ConstructorParameters<typeof HealthController>[1]);
    const out = await controller.mapPipeline();
    expect(out.status).toBe('ok');
    expect(out.alerts).toHaveLength(0);
  });

  it('mapDeep returns ok with postgis path when query succeeds', async () => {
    const prisma = {
      $queryRaw: jest.fn().mockResolvedValueOnce([{ c: 2n }]),
    } as unknown as ConstructorParameters<typeof HealthController>[0];
    const controller = new HealthController(prisma, {} as ConstructorParameters<typeof HealthController>[1]);
    const out = await controller.mapDeep();
    expect(out.queryPath).toBe('postgis_dwithin');
    expect(out.matchCount).toBe(2);
    expect(out.status).toBe('ok');
  });

  it('mapDeep falls back to bbox when postgis query throws', async () => {
    const prisma = {
      $queryRaw: jest
        .fn()
        .mockRejectedValueOnce(new Error('no postgis'))
        .mockResolvedValueOnce([{ c: 1n }]),
    } as unknown as ConstructorParameters<typeof HealthController>[0];
    const controller = new HealthController(prisma, {} as ConstructorParameters<typeof HealthController>[1]);
    const out = await controller.mapDeep();
    expect(out.queryPath).toBe('bbox_fallback');
    expect(out.alerts.some((a) => a.includes('postgis_unavailable'))).toBe(true);
  });
});
