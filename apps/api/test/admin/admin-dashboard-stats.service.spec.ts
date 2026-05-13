/// <reference types="jest" />

import { AdminDashboardStatsService } from '../../src/admin/admin-dashboard-stats.service';

describe('AdminDashboardStatsService', () => {
  it('reportDailyCountsSince delegates to $queryRaw', async () => {
    const $queryRaw = jest.fn().mockResolvedValue([{ date: '2026-01-01', count: 3n }]);
    const prisma = { $queryRaw } as never;
    const svc = new AdminDashboardStatsService(prisma);
    const since = new Date('2026-01-01T00:00:00.000Z');
    const rows = await svc.reportDailyCountsSince(since);
    expect($queryRaw).toHaveBeenCalled();
    expect(rows).toEqual([{ date: '2026-01-01', count: 3n }]);
  });
});
