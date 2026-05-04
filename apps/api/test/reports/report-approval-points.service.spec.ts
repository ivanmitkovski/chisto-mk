/// <reference types="jest" />
import { ReportCleanupEffort } from '../../src/prisma-client';
import { ReportApprovalPointsService } from '../../src/reports/report-approval-points.service';
import { ReportPointsService } from '../../src/reports/report-points.service';

describe('ReportApprovalPointsService', () => {
  const report = {
    id: 'rep-1',
    reporterId: 'user-1',
    siteId: 'site-1',
    mediaUrls: ['a.jpg', 'b.jpg'],
    severity: 5,
    cleanupEffort: ReportCleanupEffort.ONE_TO_TWO,
  };

  it('credits capped remainder when daily cap almost full', async () => {
    const reportPoints = new ReportPointsService();
    const ecoEventPoints = { creditIfNew: jest.fn().mockResolvedValue(5) };
    const svc = new ReportApprovalPointsService(reportPoints, ecoEventPoints as never);

    const tx = {
      report: {
        count: jest.fn().mockResolvedValue(0),
      },
      pointTransaction: {
        aggregate: jest.fn().mockResolvedValue({ _sum: { delta: 75 } }),
      },
    };

    const { awarded, preCapTotal } = await svc.creditApprovalIfEligible(tx as never, {
      report,
      now: new Date('2026-06-15T12:00:00.000Z'),
    });

    expect(preCapTotal).toBe(8 + 2 + 4 + 3 + 18);
    expect(awarded).toBe(5);
    expect(ecoEventPoints.creditIfNew).toHaveBeenCalledWith(
      tx,
      expect.objectContaining({
        userId: 'user-1',
        delta: 5,
        reasonCode: 'REPORT_APPROVED',
        referenceType: 'Report',
        referenceId: 'rep-1',
      }),
    );
  });

  it('debits sum of positive report-scoped grants once', async () => {
    const reportPoints = new ReportPointsService();
    const ecoEventPoints = { debitOnceIfNew: jest.fn().mockResolvedValue(-30) };
    const svc = new ReportApprovalPointsService(reportPoints, ecoEventPoints as never);

    const tx = {
      pointTransaction: {
        aggregate: jest.fn().mockResolvedValue({ _sum: { delta: 30 } }),
      },
    };

    const applied = await svc.debitRevokedApprovalIfNeeded(tx as never, {
      reportId: 'rep-1',
      userId: 'user-1',
    });

    expect(applied).toBe(-30);
    expect(ecoEventPoints.debitOnceIfNew).toHaveBeenCalledWith(
      tx,
      expect.objectContaining({
        userId: 'user-1',
        delta: -30,
        reasonCode: 'REPORT_APPROVAL_REVOKED',
      }),
    );
  });
});
