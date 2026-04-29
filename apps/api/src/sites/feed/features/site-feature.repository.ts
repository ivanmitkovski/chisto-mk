import { Injectable } from '@nestjs/common';
import { Prisma } from '../../../prisma-client';
import { PrismaService } from '../../../prisma/prisma.service';

export type SiteFeatureSnapshotRow = {
  siteId: string;
  velocity24h: number;
  discussionRatio: number;
  intentRatio: number;
  freshnessHours: number;
  severityIndex: number;
};

@Injectable()
export class SiteFeatureRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findMany(siteIds: string[]): Promise<Map<string, SiteFeatureSnapshotRow>> {
    if (siteIds.length === 0) return new Map();
    const rows = await this.prisma.$queryRaw<SiteFeatureSnapshotRow[]>`
      SELECT
        "siteId",
        "velocity24h",
        "discussionRatio",
        "intentRatio",
        "freshnessHours",
        "severityIndex"
      FROM "SiteFeatureSnapshot"
      WHERE "siteId" IN (${Prisma.join(siteIds)})
    `;
    return new Map<string, SiteFeatureSnapshotRow>(rows.map((row: SiteFeatureSnapshotRow) => [row.siteId, row]));
  }

  async upsertFromLive(input: {
    siteId: string;
    velocity24h: number;
    discussionRatio: number;
    intentRatio: number;
    freshnessHours: number;
    severityIndex: number;
  }): Promise<void> {
    await this.prisma.$executeRaw`
      INSERT INTO "SiteFeatureSnapshot"
        ("siteId","velocity24h","discussionRatio","intentRatio","freshnessHours","severityIndex","updatedAt")
      VALUES
        (${input.siteId}, ${input.velocity24h}, ${input.discussionRatio}, ${input.intentRatio}, ${input.freshnessHours}, ${input.severityIndex}, NOW())
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
}
