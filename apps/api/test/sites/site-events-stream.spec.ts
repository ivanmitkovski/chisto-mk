import { UnauthorizedException } from '@nestjs/common';
import { firstValueFrom, of, take, toArray } from 'rxjs';

jest.mock('../../src/config/map.config', () => ({
  loadMapConfig: () => require('../helpers/mock-map-config').mockMapConfigNoRedis(),
}));

import {
  buildSiteEventsStream,
  sanitizeSiteEventForPublicStream,
} from '../../src/sites/http/site-events-stream';
import { SiteEvent } from '../../src/admin-realtime/types/site-events.types';

describe('buildSiteEventsStream', () => {
  it('throws unauthorized when user is missing', () => {
    expect(() =>
      buildSiteEventsStream(
        {
          getReplaySince: jest.fn(async () => []),
          getEvents: jest.fn(),
        } as any,
        undefined,
      ),
    ).toThrow(UnauthorizedException);
  });

  it('emits replay events with SSE id mapped to eventId', async () => {
    const stream = buildSiteEventsStream(
      {
        getReplaySince: jest.fn(async () => [
          {
            eventId: 'site_1:100:site_created',
            type: 'site_created',
            siteId: 'site_1',
            occurredAtMs: 100,
            updatedAt: '2026-01-01T00:00:00.000Z',
            mutation: { kind: 'created' },
          },
        ]),
        getEvents: jest.fn(() => of()),
      } as any,
      { userId: 'u1' } as any,
    );

    const events = await firstValueFrom(stream.pipe(take(1), toArray()));
    expect(events[0]).toMatchObject({
      id: 'site_1:100:site_created',
      type: 'site_created',
      data: expect.objectContaining({ siteId: 'site_1' }),
    });
  });

  it('strips coordinates from REPORTED site events on the public stream', async () => {
    const stream = buildSiteEventsStream(
      {
        getReplaySince: jest.fn(async () => [
          {
            eventId: 'site_2:200:site_created',
            type: 'site_created',
            siteId: 'site_2',
            occurredAtMs: 200,
            updatedAt: '2026-01-01T00:00:00.000Z',
            mutation: {
              kind: 'created',
              status: 'REPORTED',
              latitude: 41.99,
              longitude: 21.43,
            },
          },
        ]),
        getEvents: jest.fn(() => of()),
      } as any,
      { userId: 'u1' } as any,
    );

    const events = await firstValueFrom(stream.pipe(take(1), toArray()));
    const data = events[0].data as SiteEvent;
    expect(data.mutation.status).toBe('REPORTED');
    expect(data.mutation.latitude).toBeUndefined();
    expect(data.mutation.longitude).toBeUndefined();
  });
});

describe('sanitizeSiteEventForPublicStream', () => {
  const baseEvent = (mutation: SiteEvent['mutation']): SiteEvent => ({
    eventId: 'site_1:100:site_created',
    type: 'site_created',
    siteId: 'site_1',
    occurredAtMs: 100,
    updatedAt: '2026-01-01T00:00:00.000Z',
    mutation,
  });

  it('removes coordinates when status is REPORTED', () => {
    const sanitized = sanitizeSiteEventForPublicStream(
      baseEvent({ kind: 'created', status: 'REPORTED', latitude: 41.99, longitude: 21.43 }),
    );
    expect(sanitized.mutation).toEqual({ kind: 'created', status: 'REPORTED' });
  });

  it('keeps coordinates for non-REPORTED statuses', () => {
    const event = baseEvent({
      kind: 'status_changed',
      status: 'VERIFIED',
      latitude: 41.99,
      longitude: 21.43,
    });
    expect(sanitizeSiteEventForPublicStream(event)).toBe(event);
  });

  it('returns event unchanged when REPORTED event has no coordinates', () => {
    const event = baseEvent({ kind: 'updated', status: 'REPORTED' });
    expect(sanitizeSiteEventForPublicStream(event)).toBe(event);
  });
});
