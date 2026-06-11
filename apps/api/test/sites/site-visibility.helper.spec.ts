import {
  mapViewerCacheKey,
  siteVisibilityPrismaWhere,
  siteVisibilitySql,
} from '../../src/sites/util/site-visibility.helper';
import { Prisma, SiteStatus } from '../../src/prisma-client';

describe('siteVisibilityPrismaWhere', () => {
  it('hides REPORTED sites for anonymous viewers', () => {
    expect(siteVisibilityPrismaWhere(null)).toEqual({
      status: { not: SiteStatus.REPORTED },
    });
  });

  it('allows reporter-owned REPORTED sites for authenticated viewers', () => {
    expect(siteVisibilityPrismaWhere('user-1')).toEqual({
      OR: [
        { status: { not: SiteStatus.REPORTED } },
        { reports: { some: { reporterId: 'user-1' } } },
        {
          reports: {
            some: { coReporters: { some: { userId: 'user-1' } } },
          },
        },
      ],
    });
  });
});

describe('siteVisibilitySql', () => {
  it('uses status column for anonymous viewers', () => {
    const sql = siteVisibilitySql({
      siteIdSql: Prisma.sql`s."siteId"`,
      siteStatusSql: Prisma.sql`s."status"`,
      viewerUserId: null,
    });
    const text = (sql as { strings: string[] }).strings.join('');
    expect(text).toContain(`<> 'REPORTED'`);
    expect(text).not.toContain('reporterId');
  });

  it('includes reporter and co-reporter clauses for authenticated viewers', () => {
    const sql = siteVisibilitySql({
      siteIdSql: Prisma.sql`s."siteId"`,
      siteStatusSql: Prisma.sql`s."status"`,
      viewerUserId: 'user-abc',
    });
    const text = (sql as { strings: string[] }).strings.join('');
    expect(text).toContain(`<> 'REPORTED'`);
    expect(text).toContain('reporterId');
    expect(text).toContain('ReportCoReporter');
  });
});

describe('mapViewerCacheKey', () => {
  it('returns anon for missing viewer', () => {
    expect(mapViewerCacheKey(null)).toBe('anon');
    expect(mapViewerCacheKey(undefined)).toBe('anon');
  });

  it('returns user id when set', () => {
    expect(mapViewerCacheKey('user-1')).toBe('user-1');
  });
});
