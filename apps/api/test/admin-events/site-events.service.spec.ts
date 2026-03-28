import { SiteEventsService } from '../../src/admin-events/site-events.service';

describe('SiteEventsService', () => {
  const originalRedisUrl = process.env.REDIS_URL;

  beforeEach(() => {
    delete process.env.REDIS_URL;
  });

  afterAll(() => {
    if (originalRedisUrl == null) {
      delete process.env.REDIS_URL;
    } else {
      process.env.REDIS_URL = originalRedisUrl;
    }
  });

  it('replays events after the provided last event id', async () => {
    const service = new SiteEventsService();
    const createdAt = new Date('2026-03-27T10:00:00.000Z');
    const updatedAt = new Date('2026-03-27T10:05:00.000Z');
    service.emitSiteCreated('site_1', {
      status: 'REPORTED',
      latitude: 41.6,
      longitude: 21.7,
      updatedAt: createdAt,
    });
    service.emitSiteUpdated('site_1', {
      kind: 'status_changed',
      status: 'VERIFIED',
      updatedAt,
    });

    await new Promise((resolve) => setImmediate(resolve));

    const replay = service.getReplaySince(`site_1:${createdAt.getTime()}:site_created`);
    expect(replay).toHaveLength(1);
    expect(replay[0]).toMatchObject({
      eventId: `site_1:${updatedAt.getTime()}:site_updated`,
      mutation: { kind: 'status_changed', status: 'VERIFIED' },
    });

    await service.onModuleDestroy();
  });

  it('returns no replay when the event id is unknown', async () => {
    const service = new SiteEventsService();
    service.emitSiteCreated('site_2', {
      updatedAt: new Date('2026-03-27T11:00:00.000Z'),
    });

    await new Promise((resolve) => setImmediate(resolve));

    expect(service.getReplaySince('missing-event')).toEqual([]);
    await service.onModuleDestroy();
  });

  it('pushes each logical event once to live observers (no Redis)', async () => {
    const service = new SiteEventsService();
    const received: string[] = [];
    const sub = service.getEvents().subscribe((e) => received.push(e.eventId));
    const at = new Date('2026-03-27T14:00:00.000Z');
    service.emitSiteCreated('site_live', { updatedAt: at });
    await new Promise((resolve) => setImmediate(resolve));
    expect(received).toHaveLength(1);
    expect(received[0]).toContain('site_live');
    sub.unsubscribe();
    await service.onModuleDestroy();
  });
});
