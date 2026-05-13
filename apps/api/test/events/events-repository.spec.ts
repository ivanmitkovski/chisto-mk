/// <reference types="jest" />

import { EventsRepository } from '../../src/events/events.repository';

describe('EventsRepository', () => {
  it('listRecurrenceSeriesEventsBatch returns empty map for empty input', async () => {
    const findMany = jest.fn();
    const prisma = { cleanupEvent: { findMany } } as never;
    const repo = new EventsRepository(prisma);
    const out = await repo.listRecurrenceSeriesEventsBatch([]);
    expect(out.size).toBe(0);
    expect(findMany).not.toHaveBeenCalled();
  });

  it('listRecurrenceSeriesEventsBatch groups rows by series root', async () => {
    const findMany = jest.fn().mockResolvedValue([
      { id: 'root', scheduledAt: new Date('2025-01-01'), parentEventId: null },
      { id: 'child', scheduledAt: new Date('2025-01-02'), parentEventId: 'root' },
    ]);
    const prisma = { cleanupEvent: { findMany } } as never;
    const repo = new EventsRepository(prisma);
    const out = await repo.listRecurrenceSeriesEventsBatch(['root']);
    expect(findMany).toHaveBeenCalled();
    const series = out.get('root');
    expect(series).toHaveLength(2);
    expect(series?.map((r) => r.id)).toEqual(['root', 'child']);
  });

  it('siteDistancesKmFromPoint returns empty map when no site ids', async () => {
    const queryRaw = jest.fn();
    const prisma = { $queryRaw: queryRaw } as never;
    const repo = new EventsRepository(prisma);
    const out = await repo.siteDistancesKmFromPoint(42, 21, []);
    expect(out.size).toBe(0);
    expect(queryRaw).not.toHaveBeenCalled();
  });

  it('siteDistancesKmFromPoint maps query rows to km numbers', async () => {
    const queryRaw = jest.fn().mockResolvedValue([
      { site_id: 's1', km: 1.5 },
      { site_id: 's2', km: '2' },
    ]);
    const prisma = { $queryRaw: queryRaw } as never;
    const repo = new EventsRepository(prisma);
    const out = await repo.siteDistancesKmFromPoint(42, 21, ['s1', 's2']);
    expect(out.get('s1')).toBe(1.5);
    expect(out.get('s2')).toBe(2);
    expect(queryRaw).toHaveBeenCalledTimes(1);
  });
});
