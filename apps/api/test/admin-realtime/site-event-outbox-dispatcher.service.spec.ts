/// <reference types="jest" />

import { SiteEventOutboxDispatcherService } from '../../src/admin-realtime/site-event-outbox-dispatcher.service';
import type { SiteEvent } from '../../src/admin-realtime/site-events.types';

describe('SiteEventOutboxDispatcherService', () => {
  const sampleEvent: SiteEvent = {
    eventId: 'evt-1',
    siteId: 'site-1',
    type: 'site_updated',
    occurredAtMs: Date.now(),
    updatedAt: new Date().toISOString(),
    mutation: { kind: 'updated' },
  };

  it('does not process when publisher is not attached', async () => {
    const prisma = {
      $queryRaw: jest.fn().mockResolvedValue([{ c: 0n }]),
      $executeRaw: jest.fn(),
    };
    const purge = { enqueueSurrogateKeys: jest.fn() };
    const svc = new SiteEventOutboxDispatcherService(prisma as any, purge as any);
    await (svc as any).processOutboxBatch();
    expect(prisma.$executeRaw).not.toHaveBeenCalled();
    expect(prisma.$queryRaw).toHaveBeenCalledTimes(1);
    const gaugeSql = String((prisma.$queryRaw as jest.Mock).mock.calls[0][0]);
    expect(gaugeSql).toContain('MapEventOutbox');
  });

  it('enqueue builds insert with ON CONFLICT DO NOTHING', async () => {
    const prevNotify = process.env.PG_OUTBOX_NOTIFY;
    process.env.PG_OUTBOX_NOTIFY = 'true';
    try {
      const prisma = {
        $executeRaw: jest.fn().mockResolvedValue(1),
        $executeRawUnsafe: jest.fn().mockResolvedValue(1),
      };
      const purge = { enqueueSurrogateKeys: jest.fn() };
      const svc = new SiteEventOutboxDispatcherService(prisma as any, purge as any);
      await svc.enqueue(sampleEvent);
      expect(prisma.$executeRaw).toHaveBeenCalled();
      const call = (prisma.$executeRaw as jest.Mock).mock.calls[0] as unknown[];
      const strings = call[0] as TemplateStringsArray;
      const sql = strings.raw.join('');
      expect(sql).toContain('ON CONFLICT');
      expect(prisma.$executeRawUnsafe).toHaveBeenCalledWith(
        expect.stringContaining('pg_notify'),
      );
    } finally {
      if (prevNotify === undefined) {
        delete process.env.PG_OUTBOX_NOTIFY;
      } else {
        process.env.PG_OUTBOX_NOTIFY = prevNotify;
      }
    }
  });
});
