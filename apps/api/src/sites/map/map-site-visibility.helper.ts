import { Prisma, ReportStatus } from '../../prisma-client';

export type MapViewerContext = {
  viewerUserId?: string | null;
};

/** Prisma filter: public sites have ≥1 approved report; else visible only to reporter/co-reporters. */
export function mapSiteVisibilityPrismaWhere(
  viewerUserId?: string | null | undefined,
): Prisma.SiteWhereInput {
  const userId = viewerUserId ?? null;
  if (userId) {
    return {
      OR: [
        { reports: { some: { status: ReportStatus.APPROVED } } },
        { reports: { some: { reporterId: userId } } },
        {
          reports: {
            some: { coReporters: { some: { userId: userId } } },
          },
        },
      ],
    };
  }
  return {
    reports: { some: { status: ReportStatus.APPROVED } },
  };
}

/**
 * Raw SQL visibility clause for map queries.
 * [siteIdSql] must reference the site id column (e.g. `"siteId"` or `s."id"`).
 */
export function mapSiteVisibilitySql(params: {
  siteIdSql: Prisma.Sql;
  viewerUserId?: string | null | undefined;
}): Prisma.Sql {
  const { siteIdSql } = params;
  const viewerUserId = params.viewerUserId ?? null;
  const approvedExists = Prisma.sql`
    EXISTS (
      SELECT 1 FROM "Report" r_vis
      WHERE r_vis."siteId" = ${siteIdSql}
        AND r_vis.status = 'APPROVED'::"ReportStatus"
    )
  `;
  if (!viewerUserId) {
    return Prisma.sql`AND ${approvedExists}`;
  }
  return Prisma.sql`AND (
    ${approvedExists}
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
