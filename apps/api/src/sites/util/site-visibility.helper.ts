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

function renderSqlFragment(fragment: Prisma.Sql): string {
  const { strings, values } = fragment;
  let out = '';
  for (let i = 0; i < strings.length; i += 1) {
    out += strings[i];
    if (i < values.length) {
      out += '?';
    }
  }
  return out;
}

/** Unqualified site id refs bind to inner EXISTS scopes and leak REPORTED sites. */
export function assertQualifiedSiteIdSql(siteIdSql: Prisma.Sql): void {
  const rendered = renderSqlFragment(siteIdSql);
  if (!rendered.includes('.')) {
    throw new Error(
      'siteVisibilitySql requires a table-qualified siteIdSql (e.g. "MapSiteProjection"."siteId" or s."id")',
    );
  }
}

/**
 * Raw SQL visibility clause for map/feed queries.
 * [siteIdSql] must be table-qualified (e.g. `"MapSiteProjection"."siteId"` or `s."id"`).
 * [siteStatusSql] must reference the outer query's site status column.
 */
export function siteVisibilitySql(params: {
  siteIdSql: Prisma.Sql;
  siteStatusSql: Prisma.Sql;
  viewerUserId?: string | null | undefined;
}): Prisma.Sql {
  const { siteIdSql, siteStatusSql } = params;
  assertQualifiedSiteIdSql(siteIdSql);
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
