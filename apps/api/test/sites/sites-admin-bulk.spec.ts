import { BadRequestException } from '@nestjs/common';
import { SitesAdminBulkService } from '../../src/sites/sites-admin-bulk.service';

describe('SitesAdminBulkService bulkSites', () => {
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
    const sitesMapQuery = { invalidateMapCache: jest.fn() } as never;
    const sitesFeed = { invalidateFeedCache: jest.fn() } as never;
    return {
      service: new SitesAdminBulkService(prisma as never, audit as never, sitesMapQuery, sitesFeed),
      prisma,
      audit,
      sitesMapQuery,
      sitesFeed,
    };
  }

  it('updates status in bulk and returns actual updated count', async () => {
    const { service, prisma } = makeService();
    const result = await service.bulkSites(
      {
        siteIds: ['s1', 's2'],
        action: 'set_status',
        status: 'VERIFIED',
      } as never,
      { userId: 'admin-1', role: 'ADMIN' } as never,
    );
    expect(result.updated).toBe(2);
    expect(prisma.site.updateMany).toHaveBeenCalled();
  });

  it('rejects set_status without status', async () => {
    const { service } = makeService();
    await expect(
      service.bulkSites(
        { siteIds: ['s1'], action: 'set_status' } as never,
        { userId: 'admin-1', role: 'ADMIN' } as never,
      ),
    ).rejects.toBeInstanceOf(BadRequestException);
  });
});
