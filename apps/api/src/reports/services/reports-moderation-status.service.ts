import { BadRequestException, Injectable, Logger, NotFoundException } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import {
  Report,
  ReportSideEffectKind,
  ReportSideEffectStatus,
  SiteStatus,
} from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';
import { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { UpdateReportStatusDto } from '../dto/update-report-status.dto';
import { ReportApprovalPointsService } from './report-approval-points.service';
import { transitionSiteToVerifiedIfFirstApproved } from '../util/report-site-verification.helper';
import { ReportSideEffectProcessorService } from '../side-effects/report-side-effect-processor.service';
import type { ModerationStatusSideEffectPayload } from '../side-effects/report-side-effect-processor.service';
import { ALLOWED_REPORT_STATUS_TRANSITIONS } from '../util/reports-moderation-transitions';
import { SiteHistoryWriterService } from '../../sites/history/site-history-writer.service';
import { SiteHistoryReportRecorderService } from '../../sites/history/site-history-report-recorder.service';
import { SiteHeroImageService, type RecomputeSiteHeroResult } from '../../sites/services/site-hero-image.service';
import { emitGamificationPointsCredited } from '../../gamification/util/gamification-credit-events.util';
import type { EcoEventPointsCreditResult } from '../../gamification/services/eco-event-points.service';

@Injectable()
export class ReportsModerationStatusService {
  private readonly logger = new Logger(ReportsModerationStatusService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly reportApprovalPoints: ReportApprovalPointsService,
    private readonly reportSideEffectProcessor: ReportSideEffectProcessorService,
    private readonly siteHistoryWriter: SiteHistoryWriterService,
    private readonly siteHistoryReportRecorder: SiteHistoryReportRecorderService,
    private readonly siteHeroImage: SiteHeroImageService,
    private readonly eventEmitter: EventEmitter2,
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
      let approvalCredit: { userId: string; credit: EcoEventPointsCreditResult } | null = null;
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
        const pointsResult = await this.reportApprovalPoints.creditApprovalIfEligible(tx, {
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
        if (updatedReport.reporterId != null && pointsResult.credit.granted > 0) {
          approvalCredit = {
            userId: updatedReport.reporterId,
            credit: pointsResult.credit,
          };
        }
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

      const moderatorActor = {
        userId: moderator.userId,
        role: moderator.role,
      };
      if (dto.status === 'APPROVED') {
        await this.siteHistoryReportRecorder.recordReportApproved(
          {
            siteId: updatedReport.siteId,
            reportId,
            occurredAt: now,
            actor: moderatorActor,
          },
          tx,
        );
      } else if (dto.status === 'DELETED') {
        await this.siteHistoryReportRecorder.recordReportRejected(
          {
            siteId: updatedReport.siteId,
            reportId,
            occurredAt: now,
            actor: moderatorActor,
            ...(dto.reason ? { metadata: { reason: dto.reason } } : {}),
          },
          tx,
        );
      }
      if (siteStatusEvent != null) {
        await this.siteHistoryWriter.recordStatusChanged(
          {
            siteId: siteStatusEvent.id,
            fromStatus: SiteStatus.REPORTED,
            toStatus: siteStatusEvent.status,
            occurredAt: siteStatusEvent.updatedAt,
            reportId,
            actor: moderatorActor,
            metadata: { trigger: 'REPORT_APPROVED' },
          },
          tx,
        );
      }

      let heroResult: RecomputeSiteHeroResult | null = null;
      if (dto.status === 'APPROVED' || dto.status === 'DELETED') {
        heroResult = await this.siteHeroImage.recomputeSiteHero(tx, updatedReport.siteId);
      }

      const coReporterUserIds = report.coReporters
        .map((c) => c.userId)
        .filter((id): id is string => id != null);
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

      return { updatedReport, siteStatusEvent, effectId: effect.id, heroResult, approvalCredit };
    });
    const updated = updatedResult.updatedReport;
    await this.reportSideEffectProcessor.processModerationStatusPost(updatedResult.effectId);
    const approvalCredit = updatedResult.approvalCredit;
    if (approvalCredit != null) {
      emitGamificationPointsCredited(
        this.eventEmitter,
        approvalCredit.userId,
        approvalCredit.credit,
      );
    }
    if (updatedResult.heroResult?.changed) {
      this.siteHeroImage.emitIfChanged(updated.siteId, updatedResult.heroResult);
    }
    this.siteHistoryWriter.emitHistoryAppended(updated.siteId, updated.id);
    this.logger.log({
      msg: 'report_moderation_status_updated',
      reportId,
      fromStatus: report.status,
      toStatus: dto.status,
      moderatorId: moderator.userId,
      siteId: updated.siteId,
    });
    return updated;
  }
}
