/// <reference types="jest" />

import { Subject } from 'rxjs';
import { SiteEventsService } from '../../src/admin-realtime/site-events.service';
import type { SiteEvent } from '../../src/admin-realtime/site-events.types';
import { MapProjectionDiffService } from '../../src/sites/map/map-projection-diff.service';
import { MapProjectionUpdaterService } from '../../src/sites/map/map-projection-updater.service';
import { MapProjectionWriterService } from '../../src/sites/map/map-projection-writer.service';

describe('MapProjectionUpdaterService', () => {
  const OLD_ENV = process.env.NODE_ENV;

  afterEach(() => {
    process.env.NODE_ENV = OLD_ENV;
    delete process.env.MAP_PROJECTION_WORKER_ENABLED;
  });

  it('elects leader in non-production when Redis is unavailable', async () => {
    process.env.NODE_ENV = 'test';
    process.env.MAP_PROJECTION_WORKER_ENABLED = 'true';

    const prisma = {
      site: { findMany: jest.fn().mockResolvedValue([]) },
      $executeRaw: jest.fn().mockResolvedValue(0),
    } as never;

    const events = new Subject<SiteEvent>();
    const siteEvents = {
      getEvents: () => events.asObservable(),
    } as unknown as SiteEventsService;

    const diff = new MapProjectionDiffService();
    const writer = {
      upsert: jest.fn().mockResolvedValue(undefined),
      deleteBySiteId: jest.fn().mockResolvedValue(undefined),
    } as unknown as MapProjectionWriterService;
    const svc = new MapProjectionUpdaterService(prisma, siteEvents, diff, writer);
    await svc.onModuleInit();
    expect((svc as any).isLeader).toBe(true);
    await svc.onModuleDestroy();
  });
});
