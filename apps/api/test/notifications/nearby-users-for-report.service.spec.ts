/// <reference types="jest" />

import {
  NearbyUsersForReportService,
  NEARBY_REPORT_RADIUS_METERS,
} from '../../src/notifications/services/nearby-users-for-report.service';

describe('NearbyUsersForReportService', () => {
  it('queries users within radius and excludes reporter/co-reporters/voters/savers', async () => {
    const queryRaw = jest.fn().mockResolvedValue([{ id: 'nearby-1' }]);
    const prisma = {
      report: {
        findMany: jest.fn().mockResolvedValue([{ reporterId: 'reporter-1' }]),
      },
      reportCoReporter: {
        findMany: jest.fn().mockResolvedValue([{ userId: 'co-1' }]),
      },
      siteVote: {
        findMany: jest.fn().mockResolvedValue([{ userId: 'voter-1' }]),
      },
      siteSave: {
        findMany: jest.fn().mockResolvedValue([{ userId: 'saver-1' }]),
      },
      $queryRaw: queryRaw,
    };

    const service = new NearbyUsersForReportService(prisma as never);
    const ids = await service.findUserIdsNearSite({
      siteId: 'site-1',
      latitude: 41.9981,
      longitude: 21.4254,
      excludeUserIds: ['extra-1'],
      radiusMeters: NEARBY_REPORT_RADIUS_METERS,
      limit: 10,
    });

    expect(ids).toEqual(['nearby-1']);
    expect(queryRaw).toHaveBeenCalledTimes(1);
  });
});
