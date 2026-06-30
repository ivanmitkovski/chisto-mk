import { SiteHeroImageService } from '../../src/sites/services/site-hero-image.service';

describe('SiteHeroImageService', () => {
  const siteEventsService = { emitSiteUpdated: jest.fn() };

  beforeEach(() => {
    jest.clearAllMocks();
  });

  function makeTx(reports: Array<{ id: string; createdAt: Date; mediaUrls: string[] }>, heroReportId: string | null) {
    return {
      report: {
        findMany: jest.fn(async () =>
          reports.map((r) => ({ id: r.id, mediaUrls: r.mediaUrls })),
        ),
      },
      site: {
        findUnique: jest.fn(async () => ({ heroReportId })),
        update: jest.fn(async () => undefined),
      },
    };
  }

  it('picks earliest approved report with non-empty media', async () => {
    const tx = makeTx(
      [
        { id: 'r1', createdAt: new Date('2026-01-01'), mediaUrls: ['a.jpg'] },
        { id: 'r2', createdAt: new Date('2026-02-01'), mediaUrls: ['b.jpg'] },
      ],
      null,
    );
    const service = new SiteHeroImageService(siteEventsService as any);
    const result = await service.recomputeSiteHero(tx as any, 'site-1');
    expect(result).toEqual({ changed: true, heroReportId: 'r1' });
    expect(tx.site.update).toHaveBeenCalledWith({
      where: { id: 'site-1' },
      data: { heroReportId: 'r1' },
    });
  });

  it('skips approved reports whose media is empty strings only', async () => {
    const tx = makeTx(
      [
        { id: 'r1', createdAt: new Date('2026-01-01'), mediaUrls: ['  '] },
        { id: 'r2', createdAt: new Date('2026-02-01'), mediaUrls: ['b.jpg'] },
      ],
      null,
    );
    const service = new SiteHeroImageService(siteEventsService as any);
    const result = await service.recomputeSiteHero(tx as any, 'site-1');
    expect(result.heroReportId).toBe('r2');
  });

  it('clears hero when no qualifying report remains', async () => {
    const tx = makeTx([], 'old-report');
    const service = new SiteHeroImageService(siteEventsService as any);
    const result = await service.recomputeSiteHero(tx as any, 'site-1');
    expect(result).toEqual({ changed: true, heroReportId: null });
  });

  it('emitIfChanged publishes site-updated only when hero changed', () => {
    const service = new SiteHeroImageService(siteEventsService as any);
    service.emitIfChanged('site-1', { changed: false, heroReportId: 'r1' });
    expect(siteEventsService.emitSiteUpdated).not.toHaveBeenCalled();
    service.emitIfChanged('site-1', { changed: true, heroReportId: 'r2' });
    expect(siteEventsService.emitSiteUpdated).toHaveBeenCalledWith('site-1', { kind: 'updated' });
  });
});
