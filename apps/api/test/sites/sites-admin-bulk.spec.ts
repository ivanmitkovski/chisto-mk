import { BadRequestException } from '@nestjs/common';
import { SitesAdminService } from '../../src/sites/sites-admin.service';

describe('SitesAdminService bulkSites', () => {
  function makeService() {
    const prisma: { site: { updateMany: jest.Mock } } = {
      site: {
        updateMany: jest.fn().mockResolvedValue({ count: 2 }),
      },
    };
    const audit: { log: jest.Mock; findByActionAndIdempotencyKey: jest.Mock } = {
      log: jest.fn().mockResolvedValue(undefined),
      findByActionAndIdempotencyKey: jest.fn().mockResolvedValue(null),
    };
    const siteEventsService = {} as never;
    const sitesMapQuery = { invalidateMapCache: jest.fn() } as never;
    const sitesFeed = { invalidateFeedCache: jest.fn() } as never;
    return {
      service: new SitesAdminService(prisma as never, audit as never, siteEventsService, sitesMapQuery, sitesFeed),
      prisma,
      audit,
      sitesMapQuery,
      sitesFeed,
    };
  }

  it('updates status in bulk and returns actual updated count', async () => {
    const { service, prisma } = makeService();
    const out = await service.bulkSites(
      { action: 'set_status', status: 'VERIFIED', siteIds: ['s1', 's2'] },
      { userId: 'admin_1' } as never,
    );
    expect(prisma.site.updateMany).toHaveBeenCalled();
    expect(out.updated).toBe(2);
  });

  it('rejects missing status for set_status', async () => {
    const { service } = makeService();
    await expect(
      service.bulkSites(
        { action: 'set_status', siteIds: ['s1'] } as never,
        { userId: 'admin_1' } as never,
      ),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('returns previous result for duplicate idempotency key', async () => {
    const { service, audit, prisma } = makeService();
    (audit.findByActionAndIdempotencyKey as jest.Mock).mockResolvedValue({
      metadata: { updated: 1, siteIds: ['s1'] },
    });
    const out = await service.bulkSites(
      { action: 'set_archived', archived: true, siteIds: ['s1'], idempotencyKey: 'k1' },
      { userId: 'admin_1' } as never,
    );
    expect(prisma.site.updateMany).not.toHaveBeenCalled();
    expect(out).toEqual({ updated: 1, siteIds: ['s1'] });
  });
});
