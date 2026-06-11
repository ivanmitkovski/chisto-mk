import { ConfigService } from '@nestjs/config';
import { SiteShareChannel } from '../../src/prisma-client';
import { SiteShareLinkService } from '../../src/sites/services/site-share-link.service';

describe('SiteShareLinkService.share', () => {
  function createService() {
    const siteShareEvent = {
      createMany: jest.fn(),
    };
    const site = {
      findUnique: jest.fn().mockResolvedValue({ id: 'site_1' }),
      update: jest.fn().mockResolvedValue({ id: 'site_1' }),
    };
    const prisma = {
      site,
      siteShareEvent,
      $transaction: jest.fn(async (fn: (tx: unknown) => Promise<unknown>) =>
        fn({ site, siteShareEvent }),
      ),
    } as never;

    const config = {
      get: jest.fn(() => undefined),
    } as unknown as ConfigService;

    return {
      service: new SiteShareLinkService(prisma, config),
      siteShareEvent,
      site,
    };
  }

  it('increments sharesCount when the user shares for the first time', async () => {
    const { service, siteShareEvent, site } = createService();
    siteShareEvent.createMany.mockResolvedValue({ count: 1 });

    await service.share('site_1', 'user_a', SiteShareChannel.native);

    expect(siteShareEvent.createMany).toHaveBeenCalledWith({
      data: [{ siteId: 'site_1', userId: 'user_a', channel: SiteShareChannel.native }],
      skipDuplicates: true,
    });
    expect(site.update).toHaveBeenCalledWith({
      where: { id: 'site_1' },
      data: { sharesCount: { increment: 1 } },
    });
  });

  it('does not increment sharesCount when the user already shared', async () => {
    const { service, siteShareEvent, site } = createService();
    siteShareEvent.createMany.mockResolvedValue({ count: 0 });

    await service.share('site_1', 'user_a', SiteShareChannel.link);

    expect(site.update).not.toHaveBeenCalled();
  });
});
