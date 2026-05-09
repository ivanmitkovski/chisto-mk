/// <reference types="jest" />

import { SiteEventOutboxDispatcherService } from '../../src/admin-events/site-event-outbox-dispatcher.service';
import type { SiteEvent } from '../../src/admin-events/site-events.types';

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
      $queryRaw: jest.fn(),
      $executeRaw: jest.fn(),
    };
    const purge = { enqueueSurrogateKeys: jest.fn() };
    const svc = new SiteEventOutboxDispatcherService(prisma as any, purge as any);
    await (svc as any).processOutboxBatch();
    expect(prisma.$queryRaw).not.toHaveBeenCalled();
  });

  it('enqueue builds insert with ON CONFLICT DO NOTHING', async () => {
    const prisma = {
      $executeRaw: jest.fn().mockResolvedValue(1),
    };
    const purge = { enqueueSurrogateKeys: jest.fn() };
    const svc = new SiteEventOutboxDispatcherService(prisma as any, purge as any);
    await svc.enqueue(sampleEvent);
    expect(prisma.$executeRaw).toHaveBeenCalled();
    const call = (prisma.$executeRaw as jest.Mock).mock.calls[0] as unknown[];
    const strings = call[0] as TemplateStringsArray;
    const sql = strings.raw.join('');
    expect(sql).toContain('ON CONFLICT');
  });
});
