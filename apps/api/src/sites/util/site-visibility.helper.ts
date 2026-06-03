import { Prisma, SiteStatus } from '../../prisma-client';

export type MapViewerContext = {
  viewerUserId?: string | null;
};

/** Prisma filter: public sites are non-REPORTED; REPORTED only for reporter/co-reporters. */
export function siteVisibilityPrismaWhere(
  viewerUserId?: string | null | undefined,
): Prisma.SiteWhereInput {
  const userId = viewerUserId ?? null;
  if (!userId) {
    return { status: { not: SiteStatus.REPORTED } };
  }
  return {
    OR: [
      { status: { not: SiteStatus.REPORTED } },
      { reports: { some: { reporterId: userId } } },
      {
        reports: {
          some: { coReporters: { some: { userId: userId } } },
        },
      },
    ],
  };
}

/**
 * Raw SQL visibility clause for map/feed queries.
 * [siteIdSql] must reference the site id column (e.g. `"siteId"` or `s."id"`).
 * [siteStatusSql] must reference the site status column (e.g. `"status"` or `s."status"`).
 */
export function siteVisibilitySql(params: {
  siteIdSql: Prisma.Sql;
  siteStatusSql: Prisma.Sql;
  viewerUserId?: string | null | undefined;
}): Prisma.Sql {
  const { siteIdSql, siteStatusSql } = params;
  const viewerUserId = params.viewerUserId ?? null;
  const publicClause = Prisma.sql`${siteStatusSql} <> 'REPORTED'::"SiteStatus"`;
  if (!viewerUserId) {
    return Prisma.sql`AND ${publicClause}`;
  }
  return Prisma.sql`AND (
    ${publicClause}
    OR EXISTS (
      SELECT 1 FROM "Report" r_vis
      WHERE r_vis."siteId" = ${siteIdSql}
        AND r_vis."reporterId" = ${viewerUserId}
    )
    OR EXISTS (
      SELECT 1 FROM "ReportCoReporter" cr_vis
      INNER JOIN "Report" r_vis ON r_vis."id" = cr_vis."reportId"
      WHERE r_vis."siteId" = ${siteIdSql}
        AND cr_vis."userId" = ${viewerUserId}
    )
  )`;
}

export function mapViewerCacheKey(viewerUserId?: string | null | undefined): string {
  return viewerUserId ?? 'anon';
}
