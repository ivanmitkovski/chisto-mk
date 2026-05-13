import { ConfigService } from '@nestjs/config';

import { SiteBookmarkService } from '../../src/sites/site-bookmark.service';
import { SiteEngagementService } from '../../src/sites/site-engagement.service';
import { SiteShareLinkService } from '../../src/sites/site-share-link.service';
import { SiteUpvoteService } from '../../src/sites/site-upvote.service';
import { signSiteShareLinkToken } from '../../src/sites/site-share-link-token';

const TOKEN_SECRET = 'unit_test_site_share_token_secret_24';
const FINGERPRINT_SECRET = 'unit_test_site_share_fingerprint_24';

describe('SiteEngagementService', () => {
  function createService() {
    const prisma = {
      siteShareLink: { findUnique: jest.fn() },
      siteShareAttributionEvent: { count: jest.fn(), createMany: jest.fn() },
      site: { update: jest.fn() },
      $transaction: jest.fn(async (fn: (tx: unknown) => Promise<unknown>) =>
        fn({
          siteShareLink: prisma.siteShareLink,
          siteShareAttributionEvent: prisma.siteShareAttributionEvent,
          site: prisma.site,
        }),
      ),
    } as any;

    const config = {
      get: jest.fn((key: string) => {
        if (key === 'SITE_SHARE_TOKEN_SECRET') return TOKEN_SECRET;
        if (key === 'SITE_SHARE_FINGERPRINT_SECRET') return FINGERPRINT_SECRET;
        if (key === 'NODE_ENV') return 'test';
        return undefined;
      }),
    } as unknown as ConfigService;

    const shareLinks = new SiteShareLinkService(prisma as never, config);
    return {
      service: new SiteEngagementService(
        {} as unknown as SiteUpvoteService,
        {} as unknown as SiteBookmarkService,
        shareLinks,
      ),
      prisma,
    };
  }

  function signedToken(siteId = 'site_1', cid = 'cid_1', expSecFromNow = 3600) {
    const nowSec = Math.floor(Date.now() / 1000);
    return signSiteShareLinkToken(Buffer.from(TOKEN_SECRET, 'utf8'), {
      s: siteId,
      c: cid,
      ch: 'native',
      iat: nowSec,
      exp: nowSec + expSecFromNow,
    });
  }

  it('increments sharesCount only once across repeated events', async () => {
    const { service, prisma } = createService();
    const token = signedToken('site_a', 'cid_a');
    const expiresAt = new Date(Date.now() + 60_000);
    const updateMany = jest.fn().mockResolvedValueOnce({ count: 1 }).mockResolvedValueOnce({ count: 0 });
    prisma.siteShareLink.findUnique.mockResolvedValue({
      id: 'link_1',
      siteId: 'site_a',
      countedAt: null,
      expiresAt,
    });
    prisma.siteShareAttributionEvent.count.mockResolvedValue(0);
    prisma.siteShareAttributionEvent.createMany.mockResolvedValue({ count: 1 });
    prisma.siteShareLink.updateMany = updateMany;
    prisma.site.update.mockResolvedValue({ id: 'site_a' });

    const first = await service.ingestAttributionEvent({
      token,
      eventType: 'CLICK',
      source: 'WEB',
      ipAddress: '203.0.113.10',
      userAgent: 'Mozilla/5.0',
      openedByUserId: undefined,
    });
    const second = await service.ingestAttributionEvent({
      token,
      eventType: 'OPEN',
      source: 'APP',
      ipAddress: '203.0.113.10',
      userAgent: 'Mozilla/5.0',
      openedByUserId: 'u1',
    });

    expect(first.counted).toBe(true);
    expect(second.counted).toBe(false);
    expect(prisma.site.update).toHaveBeenCalledTimes(1);
  });

  it('throws stable invalid-token code on signature mismatch', async () => {
    const { service } = createService();
    const token = `${signedToken()}x`;
    await expect(
      service.ingestAttributionEvent({
        token,
        eventType: 'CLICK',
        source: 'WEB',
        ipAddress: null,
        userAgent: null,
        openedByUserId: undefined,
      }),
    ).rejects.toMatchObject({ response: { code: 'SITES_SHARE_TOKEN_INVALID' } });
  });

  it('throws stable expired-token code on expired token', async () => {
    const { service } = createService();
    const token = signedToken('site_a', 'cid_a', -10);
    await expect(
      service.ingestAttributionEvent({
        token,
        eventType: 'CLICK',
        source: 'WEB',
        ipAddress: null,
        userAgent: null,
        openedByUserId: undefined,
      }),
    ).rejects.toMatchObject({ response: { code: 'SITES_SHARE_TOKEN_EXPIRED' } });
  });

  it('throws token-not-found when persisted cid row is missing', async () => {
    const { service, prisma } = createService();
    prisma.siteShareLink.findUnique.mockResolvedValue(null);
    const token = signedToken('site_a', 'cid_missing');
    await expect(
      service.ingestAttributionEvent({
        token,
        eventType: 'CLICK',
        source: 'WEB',
        ipAddress: null,
        userAgent: null,
        openedByUserId: undefined,
      }),
    ).rejects.toMatchObject({ response: { code: 'SITES_SHARE_TOKEN_NOT_FOUND' } });
  });

  it('throws token-not-found on site mismatch between token and persisted row', async () => {
    const { service, prisma } = createService();
    prisma.siteShareLink.findUnique.mockResolvedValue({
      id: 'link_1',
      siteId: 'other_site',
      countedAt: null,
      expiresAt: new Date(Date.now() + 60_000),
    });
    const token = signedToken('site_from_token', 'cid_1');
    await expect(
      service.ingestAttributionEvent({
        token,
        eventType: 'CLICK',
        source: 'WEB',
        ipAddress: null,
        userAgent: null,
        openedByUserId: undefined,
      }),
    ).rejects.toMatchObject({ response: { code: 'SITES_SHARE_TOKEN_NOT_FOUND' } });
  });

  it('throws expired when DB row expiresAt is already elapsed', async () => {
    const { service, prisma } = createService();
    prisma.siteShareLink.findUnique.mockResolvedValue({
      id: 'link_1',
      siteId: 'site_a',
      countedAt: null,
      expiresAt: new Date(Date.now() - 1_000),
    });
    const token = signedToken('site_a', 'cid_1');
    await expect(
      service.ingestAttributionEvent({
        token,
        eventType: 'CLICK',
        source: 'WEB',
        ipAddress: null,
        userAgent: null,
        openedByUserId: undefined,
      }),
    ).rejects.toMatchObject({ response: { code: 'SITES_SHARE_TOKEN_EXPIRED' } });
  });
});
