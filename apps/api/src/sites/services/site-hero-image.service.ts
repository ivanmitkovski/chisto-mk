import { Injectable } from '@nestjs/common';
import { Prisma } from '../../prisma-client';
import { SiteEventsService } from '../../admin-realtime/services/site-events.service';

export type RecomputeSiteHeroResult = {
  changed: boolean;
  heroReportId: string | null;
};

function reportHasNonEmptyMedia(mediaUrls: string[] | null | undefined): boolean {
  return (mediaUrls ?? []).some((url) => typeof url === 'string' && url.trim().length > 0);
}

@Injectable()
export class SiteHeroImageService {
  constructor(private readonly siteEventsService: SiteEventsService) {}

  /**
   * Sets heroReportId to the earliest APPROVED report on the site that has media,
   * or null when none qualify.
   */
  async recomputeSiteHero(
    tx: Prisma.TransactionClient,
    siteId: string,
  ): Promise<RecomputeSiteHeroResult> {
    const candidates = await tx.report.findMany({
      where: {
        siteId,
        status: 'APPROVED',
        NOT: { mediaUrls: { equals: [] } },
      },
      orderBy: [{ createdAt: 'asc' }, { id: 'asc' }],
      select: { id: true, mediaUrls: true },
    });

    const hero = candidates.find((report) => reportHasNonEmptyMedia(report.mediaUrls));
    const nextHeroReportId = hero?.id ?? null;

    const current = await tx.site.findUnique({
      where: { id: siteId },
      select: { heroReportId: true },
    });

    const changed = (current?.heroReportId ?? null) !== nextHeroReportId;
    if (changed) {
      await tx.site.update({
        where: { id: siteId },
        data: { heroReportId: nextHeroReportId },
      });
    }

    return { changed, heroReportId: nextHeroReportId };
  }

  emitIfChanged(siteId: string, result: RecomputeSiteHeroResult): void {
    if (result.changed) {
      this.siteEventsService.emitSiteUpdated(siteId, { kind: 'updated' });
    }
  }
}
