import { mapSiteVisibilityPrismaWhere } from '../../src/sites/map/map-site-visibility.helper';
import { ReportStatus } from '../../src/prisma-client';

describe('mapSiteVisibilityPrismaWhere', () => {
  it('requires an approved report for anonymous viewers', () => {
    expect(mapSiteVisibilityPrismaWhere(null)).toEqual({
      reports: { some: { status: ReportStatus.APPROVED } },
    });
  });

  it('allows reporter-owned pending sites for authenticated viewers', () => {
    expect(mapSiteVisibilityPrismaWhere('user-1')).toEqual({
      OR: [
        { reports: { some: { status: ReportStatus.APPROVED } } },
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
