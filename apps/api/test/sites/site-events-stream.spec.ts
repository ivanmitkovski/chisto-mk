import { UnauthorizedException } from '@nestjs/common';
import { firstValueFrom, of, take, toArray } from 'rxjs';
import { buildSiteEventsStream } from '../../src/sites/http/site-events-stream';

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
});
