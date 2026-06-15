import {
  viewerResolutionStatusForSite,
} from '../../src/sites/resolutions/util/viewer-resolution-status';
import { SiteResolutionQueryService } from '../../src/sites/resolutions/services/site-resolution-query.service';
import { SiteResolutionStatus } from '../../src/prisma-client';

describe('viewerResolutionStatusForSite', () => {
  it('returns none when site absent from map', () => {
    expect(viewerResolutionStatusForSite(new Map(), 'site_1')).toBe('none');
  });

  it('returns pending and approved from map', () => {
    const map = new Map<string, 'pending' | 'approved'>([
      ['site_a', 'pending'],
      ['site_b', 'approved'],
    ]);
    expect(viewerResolutionStatusForSite(map, 'site_a')).toBe('pending');
    expect(viewerResolutionStatusForSite(map, 'site_b')).toBe('approved');
  });
});

describe('SiteResolutionQueryService.getViewerStatusBySiteIds', () => {
  it('returns empty map for empty site ids', async () => {
    const prisma = { siteResolution: { findMany: jest.fn() } };
    const service = new SiteResolutionQueryService(prisma as never, {} as never);
    const out = await service.getViewerStatusBySiteIds('user_1', []);
    expect(out.size).toBe(0);
    expect(prisma.siteResolution.findMany).not.toHaveBeenCalled();
  });

  it('prefers APPROVED over PENDING for the same site', async () => {
    const prisma = {
      siteResolution: {
        findMany: jest.fn(async () => [
          { siteId: 'site_1', status: SiteResolutionStatus.PENDING },
          { siteId: 'site_1', status: SiteResolutionStatus.APPROVED },
        ]),
      },
    };
    const service = new SiteResolutionQueryService(prisma as never, {} as never);
    const out = await service.getViewerStatusBySiteIds('user_1', ['site_1']);
    expect(out.get('site_1')).toBe('approved');
  });

  it('returns pending when only pending exists', async () => {
    const prisma = {
      siteResolution: {
        findMany: jest.fn(async () => [
          { siteId: 'site_2', status: SiteResolutionStatus.PENDING },
        ]),
      },
    };
    const service = new SiteResolutionQueryService(prisma as never, {} as never);
    const out = await service.getViewerStatusBySiteIds('user_1', ['site_2']);
    expect(out.get('site_2')).toBe('pending');
  });
});
