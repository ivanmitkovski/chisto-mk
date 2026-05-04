/// <reference types="jest" />
import { filter, firstValueFrom, take, timeout } from 'rxjs';
import { RedisReportEventBus } from '../../src/reports/owner-events/report-event-bus';
import type { OwnerReportEvent } from '../../src/reports/reports-owner-events.types';

const redisUrl = process.env.REDIS_URL?.trim();

(redisUrl ? describe : describe.skip)('RedisReportEventBus (integration)', () => {
  let left: RedisReportEventBus;
  let right: RedisReportEventBus;

  beforeAll(() => {
    left = new RedisReportEventBus(redisUrl!);
    right = new RedisReportEventBus(redisUrl!);
  });

  afterAll(() => {
    left.dispose();
    right.dispose();
  });

  it('delivers publish from one connection to a subscriber on another', async () => {
    const evt: OwnerReportEvent = {
      eventId: 'evt-redis-1',
      type: 'report_updated',
      ownerId: 'user-a',
      reportId: 'rep-a',
      occurredAtMs: Date.now(),
      mutation: { kind: 'updated' },
    };

    const received = firstValueFrom(
      right.subscribe().pipe(
        filter((e) => e.eventId === evt.eventId),
        take(1),
        timeout({ first: 8000 }),
      ),
    );

    await new Promise((r) => setTimeout(r, 250));
    left.publish(evt);
    const out = await received;
    expect(out.reportId).toBe('rep-a');
    expect(out.ownerId).toBe('user-a');
  });

  it('delivers media_appended mutation payload', async () => {
    const evt: OwnerReportEvent = {
      eventId: `evt-redis-media-${Date.now()}`,
      type: 'report_updated',
      ownerId: 'user-b',
      reportId: 'rep-b',
      occurredAtMs: Date.now(),
      mutation: { kind: 'media_appended', status: 'NEW' },
    };

    const received = firstValueFrom(
      right.subscribe().pipe(
        filter((e) => e.eventId === evt.eventId),
        take(1),
        timeout({ first: 8000 }),
      ),
    );

    await new Promise((r) => setTimeout(r, 250));
    left.publish(evt);
    const out = await received;
    expect(out.mutation.kind).toBe('media_appended');
    if (out.mutation.kind === 'media_appended') {
      expect(out.mutation.status).toBe('NEW');
    }
  });
});
