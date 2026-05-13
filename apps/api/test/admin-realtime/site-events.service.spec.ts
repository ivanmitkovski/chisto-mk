import { SiteEventsService } from '../../src/admin-realtime/site-events.service';
import { SiteEventOutboxDispatcherService } from '../../src/admin-realtime/site-event-outbox-dispatcher.service';
import { SiteEventPublisherService } from '../../src/admin-realtime/site-event-publisher.service';
import { SiteEventReplayStoreService } from '../../src/admin-realtime/site-event-replay-store.service';

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
    const createdAt = new Date('2026-03-27T10:00:00.000Z');
    const updatedAt = new Date('2026-03-27T10:05:00.000Z');
    const publisher = {
      getEvents: jest.fn(() => ({ subscribe: jest.fn() })),
      getReplaySinceMemory: jest
        .fn()
        .mockReturnValueOnce([])
        .mockReturnValueOnce([
          {
            eventId: 'site_1:1711533900000:site_updated',
            type: 'site_updated',
            siteId: 'site_1',
            occurredAtMs: 1711533900000,
            updatedAt: '2026-03-27T10:05:00.000Z',
            mutation: { kind: 'status_changed', status: 'VERIFIED' },
          },
        ]),
      publish: jest.fn(),
      onModuleDestroy: jest.fn(async () => undefined),
    } as unknown as SiteEventPublisherService;
    const outbox = {
      attachPublisher: jest.fn(),
      enqueue: jest.fn(async () => undefined),
      kickNow: jest.fn(),
      onModuleInit: jest.fn(),
      onModuleDestroy: jest.fn(async () => undefined),
    } as unknown as SiteEventOutboxDispatcherService;
    const replayStore = {
      getReplaySinceFromDatabase: jest.fn(async () => [
        {
          eventId: `site_1:${updatedAt.getTime()}:site_updated`,
          type: 'site_updated',
          siteId: 'site_1',
          occurredAtMs: updatedAt.getTime(),
          updatedAt: updatedAt.toISOString(),
          mutation: { kind: 'status_changed', status: 'VERIFIED' },
        },
      ]),
    } as unknown as SiteEventReplayStoreService;
    const service = new SiteEventsService(publisher, outbox, replayStore);
    service.onModuleInit();
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

    const replay = await service.getReplaySince(`site_1:${createdAt.getTime()}:site_created`);
    expect(replay).toHaveLength(1);
    expect(replay[0]).toMatchObject({
      eventId: `site_1:${updatedAt.getTime()}:site_updated`,
      mutation: { kind: 'status_changed', status: 'VERIFIED' },
    });

    await service.onModuleDestroy();
  });

  it('returns no replay when the event id is unknown', async () => {
    const publisher = {
      getEvents: jest.fn(() => ({ subscribe: jest.fn() })),
      getReplaySinceMemory: jest.fn(() => []),
      publish: jest.fn(),
      onModuleDestroy: jest.fn(async () => undefined),
    } as unknown as SiteEventPublisherService;
    const outbox = {
      attachPublisher: jest.fn(),
      enqueue: jest.fn(async () => undefined),
      kickNow: jest.fn(),
      onModuleInit: jest.fn(),
      onModuleDestroy: jest.fn(async () => undefined),
    } as unknown as SiteEventOutboxDispatcherService;
    const replayStore = {
      getReplaySinceFromDatabase: jest.fn(async () => []),
    } as unknown as SiteEventReplayStoreService;
    const service = new SiteEventsService(publisher, outbox, replayStore);
    expect(await service.getReplaySince('missing-event')).toEqual([]);
    await service.onModuleDestroy();
  });

  it('pushes each logical event once to live observers (no Redis)', async () => {
    const events: Array<{ eventId: string }> = [];
    const publisher = {
      getEvents: jest.fn(() => ({
        subscribe: (handler: (e: { eventId: string }) => void) => {
          const event = { eventId: 'site_live:1711548000000:site_created' };
          events.push(event);
          handler(event);
          return { unsubscribe: jest.fn() };
        },
      })),
      getReplaySinceMemory: jest.fn(() => []),
      publish: jest.fn(),
      onModuleDestroy: jest.fn(async () => undefined),
    } as unknown as SiteEventPublisherService;
    const outbox = {
      attachPublisher: jest.fn(),
      enqueue: jest.fn(async () => undefined),
      kickNow: jest.fn(),
      onModuleInit: jest.fn(),
      onModuleDestroy: jest.fn(async () => undefined),
    } as unknown as SiteEventOutboxDispatcherService;
    const replayStore = {
      getReplaySinceFromDatabase: jest.fn(async () => []),
    } as unknown as SiteEventReplayStoreService;
    const service = new SiteEventsService(publisher, outbox, replayStore);
    const received: string[] = [];
    const sub = service.getEvents().subscribe((e) => received.push(e.eventId));
    expect(received).toHaveLength(1);
    expect(received[0]).toContain('site_live');
    sub.unsubscribe();
    await service.onModuleDestroy();
  });
});
