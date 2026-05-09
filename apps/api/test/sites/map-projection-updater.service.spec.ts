/// <reference types="jest" />

import { Subject } from 'rxjs';
import { SiteEventsService } from '../../src/admin-events/site-events.service';
import type { SiteEvent } from '../../src/admin-events/site-events.types';
import { MapProjectionUpdaterService } from '../../src/sites/map/map-projection-updater.service';

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

    const svc = new MapProjectionUpdaterService(prisma, siteEvents);
    await svc.onModuleInit();
    expect((svc as any).isLeader).toBe(true);
    await svc.onModuleDestroy();
  });
});
