import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import {
  Report,
  ReportSideEffectKind,
  ReportSideEffectStatus,
  SiteStatus,
} from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { UpdateReportStatusDto } from './dto/update-report-status.dto';
import { ReportApprovalPointsService } from './report-approval-points.service';
import { transitionSiteToVerifiedIfFirstApproved } from './report-site-verification.helper';
import { ReportSideEffectProcessorService } from './side-effects/report-side-effect-processor.service';
import type { ModerationStatusSideEffectPayload } from './side-effects/report-side-effect-processor.service';
import { ALLOWED_REPORT_STATUS_TRANSITIONS } from './reports-moderation-transitions';

@Injectable()
export class ReportsModerationStatusService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly reportApprovalPoints: ReportApprovalPointsService,
    private readonly reportSideEffectProcessor: ReportSideEffectProcessorService,
  ) {}

  async updateStatus(
    reportId: string,
    dto: UpdateReportStatusDto,
    moderator: AuthenticatedUser,
  ): Promise<Report> {
    const report = await this.prisma.report.findUnique({
      where: { id: reportId },
      select: {
        id: true,
        status: true,
        reporterId: true,
        siteId: true,
        coReporters: { select: { userId: true } },
      },
    });

    if (!report) {
      throw new NotFoundException({
        code: 'REPORT_NOT_FOUND',
        message: `Report with id '${reportId}' was not found`,
      });
    }

    if (report.status === dto.status) {
      return this.prisma.report.findUniqueOrThrow({
        where: { id: reportId },
      });
    }

    const allowedStatuses = ALLOWED_REPORT_STATUS_TRANSITIONS[report.status];
    if (!allowedStatuses.includes(dto.status)) {
      throw new BadRequestException({
        code: 'INVALID_REPORT_STATUS_TRANSITION',
        message: `Cannot transition report status from '${report.status}' to '${dto.status}'`,
        details: {
          from: report.status,
          to: dto.status,
          allowedTo: allowedStatuses,
        },
      });
    }

    const now = new Date();

    const updatedResult = await this.prisma.$transaction(async (tx) => {
      const updatedReport = await tx.report.update({
        where: { id: reportId },
        data: {
          status: dto.status,
          moderatedAt: now,
          moderationReason: dto.reason ?? null,
          moderatedById: moderator.userId,
        },
      });

      if (dto.status === 'APPROVED') {
        await this.reportApprovalPoints.creditApprovalIfEligible(tx, {
          report: {
            id: updatedReport.id,
            reporterId: updatedReport.reporterId,
            siteId: updatedReport.siteId,
            mediaUrls: updatedReport.mediaUrls,
            severity: updatedReport.severity,
            cleanupEffort: updatedReport.cleanupEffort,
          },
          now,
        });
      }

      if (dto.status === 'DELETED' && report.status === 'APPROVED' && report.reporterId) {
        await this.reportApprovalPoints.debitRevokedApprovalIfNeeded(tx, {
          reportId,
          userId: report.reporterId,
        });
      }

      let siteStatusEvent: {
        id: string;
        status: SiteStatus;
        latitude: number;
        longitude: number;
        updatedAt: Date;
      } | null = null;
      if (dto.status === 'APPROVED') {
        const otherApprovedCount = await tx.report.count({
          where: {
            siteId: updatedReport.siteId,
            status: 'APPROVED',
            id: { not: reportId },
          },
        });
        if (otherApprovedCount === 0) {
          siteStatusEvent = await transitionSiteToVerifiedIfFirstApproved(tx, updatedReport.siteId);
        }
      }

      const coReporterUserIds = report.coReporters.map((c) => c.userId);
      const moderationPayload: ModerationStatusSideEffectPayload = {
        moderatorUserId: moderator.userId,
        reportId,
        fromStatus: report.status,
        toStatus: dto.status,
        reason: dto.reason ?? null,
        siteId: updatedReport.siteId,
        reporterId: report.reporterId,
        coReporterUserIds,
        siteStatusEvent:
          siteStatusEvent == null
            ? null
            : {
                id: siteStatusEvent.id,
                status: siteStatusEvent.status,
                latitude: siteStatusEvent.latitude,
                longitude: siteStatusEvent.longitude,
                updatedAt: siteStatusEvent.updatedAt.toISOString(),
              },
      };

      const effect = await tx.reportSideEffect.create({
        data: {
          kind: ReportSideEffectKind.MODERATION_STATUS_POST,
          status: ReportSideEffectStatus.PENDING,
          payload: moderationPayload as object,
        },
      });

      return { updatedReport, siteStatusEvent, effectId: effect.id };
    });
    const updated = updatedResult.updatedReport;
    await this.reportSideEffectProcessor.processModerationStatusPost(updatedResult.effectId);
    return updated;
  }
}
