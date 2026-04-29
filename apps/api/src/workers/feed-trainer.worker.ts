import { Logger } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

type FeedTrainingSample = {
  userId: string;
  siteId: string;
  label: 0 | 1;
  position: number;
  dwellMs: number;
  variant: string;
  createdAt: Date;
};

/**
 * Scaffold worker for nightly feed ranking training.
 * Export/publish orchestration is handled by external job runner in deployment.
 */
export class FeedTrainerWorker {
  private readonly logger = new Logger(FeedTrainerWorker.name);

  constructor(private readonly prisma: PrismaService) {}

  async collectSamples(windowHours = 24): Promise<FeedTrainingSample[]> {
    const rows = await this.prisma.$queryRaw<FeedTrainingSample[]>`
      SELECT
        "userId",
        "siteId",
        CASE WHEN "engaged" = true THEN 1 ELSE 0 END AS "label",
        COALESCE("position", 0) AS "position",
        COALESCE("dwellMs", 0) AS "dwellMs",
        "variant",
        "createdAt"
      FROM "FeedImpression"
      WHERE "createdAt" >= NOW() - (${windowHours} || ' hours')::interval
      ORDER BY "createdAt" DESC
      LIMIT 250000
    `;
    return rows;
  }

  async refreshSiteFeatureSnapshots(limit = 1000): Promise<number> {
    const sites = await this.prisma.site.findMany({
      orderBy: { updatedAt: 'desc' },
      take: Math.min(Math.max(limit, 1), 5000),
      select: {
        id: true,
        createdAt: true,
        upvotesCount: true,
        commentsCount: true,
        savesCount: true,
        sharesCount: true,
        status: true,
      },
    });
    for (const site of sites) {
      const ageHours = Math.max(
        0,
        (Date.now() - site.createdAt.getTime()) / (1000 * 60 * 60),
      );
      const engagement =
        site.upvotesCount + site.commentsCount + site.savesCount + site.sharesCount;
      await this.prisma.$executeRaw`
        INSERT INTO "SiteFeatureSnapshot"
          ("siteId","velocity24h","discussionRatio","intentRatio","freshnessHours","severityIndex","updatedAt")
        VALUES
          (
            ${site.id},
            ${Math.min(1, engagement / 50)},
            ${engagement > 0 ? site.commentsCount / engagement : 0},
            ${engagement > 0 ? (site.savesCount + site.sharesCount) / engagement : 0},
            ${ageHours},
            ${site.status === 'DISPUTED' ? 0.2 : site.status === 'VERIFIED' ? 0.8 : 0.55},
            NOW()
          )
        ON CONFLICT ("siteId")
        DO UPDATE SET
          "velocity24h" = EXCLUDED."velocity24h",
          "discussionRatio" = EXCLUDED."discussionRatio",
          "intentRatio" = EXCLUDED."intentRatio",
          "freshnessHours" = EXCLUDED."freshnessHours",
          "severityIndex" = EXCLUDED."severityIndex",
          "updatedAt" = NOW()
      `;
    }
    return sites.length;
  }

  async runNightly(): Promise<void> {
    const refreshed = await this.refreshSiteFeatureSnapshots();
    const samples = await this.collectSamples(24);
    this.logger.log(
      `Feed trainer refreshed ${refreshed} feature snapshots and collected ${samples.length} samples.`,
    );
  }
}
