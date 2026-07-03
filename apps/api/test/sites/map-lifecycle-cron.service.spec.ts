/// <reference types="jest" />

import { mockMapConfigNoRedis } from '../helpers/mock-map-config';

jest.mock('../../src/config/map.config', () => ({
  loadMapConfig: () => mockMapConfigNoRedis,
}));

import { MapLifecycleCronService } from '../../src/sites/map/map-lifecycle-cron.service';

describe('MapLifecycleCronService', () => {
  const OLD_ENV = process.env.NODE_ENV;

  afterEach(() => {
    process.env.NODE_ENV = OLD_ENV;
    delete process.env.MAP_LIFECYCLE_CRON_ENABLED;
  });

  it('runs refreshHotness when elected leader without Redis in test', async () => {
    process.env.NODE_ENV = 'test';
    process.env.MAP_LIFECYCLE_CRON_ENABLED = 'true';

    const prisma = {
      $executeRaw: jest.fn().mockResolvedValue(1),
      $queryRaw: jest
        .fn()
        .mockResolvedValue([{ rows_total: 1, hot_rows: 1, oldest_hot_seconds: null }]),
    };

    const svc = new MapLifecycleCronService(prisma as any);
    await (svc as any).refreshHotness();
    expect(prisma.$executeRaw).toHaveBeenCalled();
    await svc.onModuleDestroy();
  });
});
