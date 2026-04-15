/// <reference types="jest" />
import { BadRequestException } from '@nestjs/common';
import { ReportsModerationService } from '../../src/reports/reports-moderation.service';
import { UpdateReportStatusDto } from '../../src/reports/dto/update-report-status.dto';
import { Role } from '../../src/prisma-client';

describe('ReportsModerationService updateStatus', () => {
  it('rejects invalid status transitions', async () => {
    const prisma: any = {
      report: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'r1',
          status: 'DELETED',
          reporterId: null,
        }),
      },
    };
    const reportsOwnerEventsService = { emit: jest.fn() };
    const eventEmitter = { emit: jest.fn() };
    const service = new ReportsModerationService(
      prisma as never,
      { log: jest.fn() } as never,
      { signUrls: jest.fn() } as never,
      { emitReportStatusUpdated: jest.fn() } as never,
      { emitSiteUpdated: jest.fn() } as never,
      reportsOwnerEventsService as never,
      eventEmitter as never,
    );
    const moderator = { userId: 'mod-1', role: Role.ADMIN };
    const dto: UpdateReportStatusDto = { status: 'APPROVED' };

    await expect(service.updateStatus('r1', dto, moderator as never)).rejects.toBeInstanceOf(
      BadRequestException,
    );
  });
});
