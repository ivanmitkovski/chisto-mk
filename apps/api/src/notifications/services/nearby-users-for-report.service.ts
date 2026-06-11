import { Injectable } from '@nestjs/common';
import { Prisma } from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';

/** Default radius for NEARBY_REPORT fan-out (meters). */
export const NEARBY_REPORT_RADIUS_METERS = 3_000;

/** Max recipients per site approval NEARBY_REPORT burst. */
export const NEARBY_REPORT_FANOUT_CAP = 200;

@Injectable()
export class NearbyUsersForReportService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Finds active users with a home location within [radiusMeters] of a site,
   * excluding reporter/co-reporters/upvoters/savers and optional extra ids.
   */
  async findUserIdsNearSite(params: {
    siteId: string;
    latitude: number;
    longitude: number;
    excludeUserIds?: string[];
    radiusMeters?: number;
    limit?: number;
  }): Promise<string[]> {
    const {
      siteId,
      latitude,
      longitude,
      excludeUserIds = [],
      radiusMeters = NEARBY_REPORT_RADIUS_METERS,
      limit = NEARBY_REPORT_FANOUT_CAP,
    } = params;

    const excluded = new Set(excludeUserIds.filter(Boolean));

    const [reporters, coReporters, upvoters, savers] = await Promise.all([
      this.prisma.report.findMany({
        where: { siteId, reporterId: { not: null } },
        select: { reporterId: true },
        take: 100,
      }),
      this.prisma.reportCoReporter.findMany({
        where: { report: { siteId } },
        select: { userId: true },
        take: 100,
      }),
      this.prisma.siteVote.findMany({
        where: { siteId },
        select: { userId: true },
        take: 200,
      }),
      this.prisma.siteSave.findMany({
        where: { siteId },
        select: { userId: true },
        take: 200,
      }),
    ]);

    for (const r of reporters) {
      if (r.reporterId) excluded.add(r.reporterId);
    }
    for (const c of coReporters) {
      if (c.userId) excluded.add(c.userId);
    }
    for (const u of upvoters) {
      if (u.userId) excluded.add(u.userId);
    }
    for (const s of savers) {
      if (s.userId) excluded.add(s.userId);
    }

    const excludeList = [...excluded];
    const excludeSql =
      excludeList.length > 0
        ? Prisma.sql`AND u."id" NOT IN (${Prisma.join(excludeList)})`
        : Prisma.empty;

    const rows = await this.prisma.$queryRaw<Array<{ id: string }>>(
      Prisma.sql`
        SELECT u."id"
        FROM "User" u
        WHERE u."status" = 'ACTIVE'
          AND u."homeLatitude" IS NOT NULL
          AND u."homeLongitude" IS NOT NULL
          AND ST_DWithin(
            ST_SetSRID(ST_MakePoint(u."homeLongitude", u."homeLatitude"), 4326)::geography,
            ST_SetSRID(ST_MakePoint(${longitude}, ${latitude}), 4326)::geography,
            ${radiusMeters}
          )
          ${excludeSql}
        LIMIT ${limit}
      `,
    );

    return rows.map((r) => r.id);
  }
}
