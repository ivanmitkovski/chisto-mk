/// <reference types="jest" />
import { BadRequestException } from '@nestjs/common';
import { ReportsModerationDetailService } from '../../src/reports/reports-moderation-detail.service';
import { ReportsModerationListService } from '../../src/reports/reports-moderation-list.service';
import { ReportsModerationService } from '../../src/reports/reports-moderation.service';
import { ReportsModerationStatusService } from '../../src/reports/reports-moderation-status.service';
import { UpdateReportStatusDto } from '../../src/reports/dto/update-report-status.dto';
import { Role } from '../../src/prisma-client';

function createModerationService(
  prisma: unknown,
  reportApprovalPoints: {
    creditApprovalIfEligible: jest.Mock;
    debitRevokedApprovalIfNeeded: jest.Mock;
  },
) {
  const reportsUploadService = { signUrls: jest.fn().mockResolvedValue([]) };
  const reportSideEffectProcessor = {
    processModerationStatusPost: jest.fn().mockResolvedValue(undefined),
  };
  const list = new ReportsModerationListService(prisma as never);
  const status = new ReportsModerationStatusService(
    prisma as never,
    reportApprovalPoints as never,
    reportSideEffectProcessor as never,
  );
  const detail = new ReportsModerationDetailService(prisma as never, reportsUploadService as never);
  const service = new ReportsModerationService(list, status, detail);
  return { service, reportSideEffectProcessor };
}

describe('ReportsModerationService updateStatus', () => {
  it('rejects invalid status transitions', async () => {
    const prisma: any = {
      report: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'r1',
          status: 'DELETED',
          reporterId: null,
          siteId: 's1',
          coReporters: [],
        }),
      },
    };
    const reportApprovalPoints = {
      creditApprovalIfEligible: jest.fn().mockResolvedValue({ awarded: 0, preCapTotal: 0 }),
      debitRevokedApprovalIfNeeded: jest.fn().mockResolvedValue(0),
    };
    const { service } = createModerationService(prisma, reportApprovalPoints);
    const moderator = { userId: 'mod-1', role: Role.ADMIN };
    const dto: UpdateReportStatusDto = { status: 'APPROVED' };

    await expect(service.updateStatus('r1', dto, moderator as never)).rejects.toBeInstanceOf(
      BadRequestException,
    );
  });

  it('revokes points when deleting an approved report', async () => {
    const reportApprovalPoints = {
      creditApprovalIfEligible: jest.fn(),
      debitRevokedApprovalIfNeeded: jest.fn().mockResolvedValue(-25),
    };
    const prisma: any = {
      report: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'r1',
          status: 'APPROVED',
          reporterId: 'u1',
          siteId: 's1',
          coReporters: [],
        }),
        findUniqueOrThrow: jest.fn().mockResolvedValue({ id: 'r1', status: 'DELETED', siteId: 's1' }),
        update: jest.fn().mockResolvedValue({
          id: 'r1',
          status: 'DELETED',
          reporterId: 'u1',
          siteId: 's1',
          mediaUrls: [],
          severity: null,
          cleanupEffort: null,
        }),
        count: jest.fn().mockResolvedValue(0),
      },
      $transaction: jest.fn(async (cb: (tx: unknown) => Promise<unknown>) => {
        const tx = {
          report: {
            update: prisma.report.update,
            count: prisma.report.count,
          },
          reportSideEffect: {
            create: jest.fn().mockResolvedValue({ id: 'mod-effect-1' }),
          },
        };
        return cb(tx);
      }),
    };
    const { service, reportSideEffectProcessor } = createModerationService(prisma, reportApprovalPoints);
    const moderator = { userId: 'mod-1', role: Role.ADMIN };
    await service.updateStatus('r1', { status: 'DELETED', reason: 'spam' }, moderator as never);
    expect(reportApprovalPoints.debitRevokedApprovalIfNeeded).toHaveBeenCalledWith(
      expect.anything(),
      { reportId: 'r1', userId: 'u1' },
    );
    expect(reportApprovalPoints.creditApprovalIfEligible).not.toHaveBeenCalled();
    expect(reportSideEffectProcessor.processModerationStatusPost).toHaveBeenCalledWith('mod-effect-1');
  });
});
