/// <reference types="jest" />
import { ReportCleanupEffort } from '../../src/prisma-client';
import { ReportPointsService } from '../../src/reports/report-points.service';

describe('ReportPointsService.computeApprovalPoints', () => {
  const svc = new ReportPointsService();

  it('includes pioneer bonus when no other approved reports on site', () => {
    const out = svc.computeApprovalPoints({
      mediaCount: 2,
      severity: 5,
      cleanupEffort: ReportCleanupEffort.ONE_TO_TWO,
      otherApprovedReportCountOnSite: 0,
    });
    expect(out.breakdown.map((b) => b.code)).toContain('REPORT_APPROVED_SITE_PIONEER');
    expect(out.preCapTotal).toBe(8 + 2 + 4 + 3 + 18);
  });

  it('applies repeat-site adjustment without pioneer bonus', () => {
    const out = svc.computeApprovalPoints({
      mediaCount: 0,
      severity: 2,
      cleanupEffort: ReportCleanupEffort.NOT_SURE,
      otherApprovedReportCountOnSite: 2,
    });
    expect(out.breakdown.map((b) => b.code)).toContain('REPORT_APPROVED_REPEAT_SITE_ADJUSTMENT');
    expect(out.breakdown.map((b) => b.code)).not.toContain('REPORT_APPROVED_SITE_PIONEER');
    expect(out.preCapTotal).toBe(Math.floor(8 * 0.55));
  });

  it('omits cleanup bonus when NOT_SURE', () => {
    const out = svc.computeApprovalPoints({
      mediaCount: 0,
      severity: 2,
      cleanupEffort: ReportCleanupEffort.NOT_SURE,
      otherApprovedReportCountOnSite: 0,
    });
    expect(out.breakdown.map((b) => b.code)).not.toContain('REPORT_APPROVED_CLEANUP_EFFORT');
  });
});
