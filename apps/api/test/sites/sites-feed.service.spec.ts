import { BadRequestException } from '@nestjs/common';
import { SitesFeedService } from '../../src/sites/sites-feed.service';

describe('SitesFeedService', () => {
  it('rejects partial geo query (lat without lng)', async () => {
    const prisma = {} as never;
    const audit = { log: jest.fn() } as never;
    const reportsUpload = { signUrls: jest.fn() } as never;
    const feedRanking = { scoreDetailed: jest.fn() } as never;
    const siteEngagement = { ensureSiteExists: jest.fn() } as never;
    const svc = new SitesFeedService(prisma, audit, reportsUpload, feedRanking, siteEngagement);

    await expect(
      svc.findAll({ lat: 41.6, page: 1, limit: 20, radiusKm: 10, sort: 'hybrid' } as never),
    ).rejects.toBeInstanceOf(BadRequestException);
  });
});
