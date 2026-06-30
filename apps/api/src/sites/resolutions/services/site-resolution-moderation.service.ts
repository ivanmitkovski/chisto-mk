import {
  BadRequestException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import {
  Prisma,
  SiteHistoryEntryKind,
  SiteResolution,
  SiteResolutionStatus,
} from '../../../prisma-client';
import { PrismaService } from '../../../prisma/prisma.service';
import { AuthenticatedUser } from '../../../auth/types/authenticated-user.type';
import { AuditService } from '../../../audit/services/audit.service';
import { SiteEventsService } from '../../../admin-realtime/services/site-events.service';
import { SiteHistoryWriterService } from '../../history/site-history-writer.service';
import { SitesFeedService } from '../../services/sites-feed.service';
import { SitesMapQueryService } from '../../services/sites-map-query.service';
import { SitesReporterNotificationService } from '../../services/sites-reporter-notification.service';
import { UpdateSiteResolutionStatusDto } from '../dto/update-site-resolution-status.dto';
import { ALLOWED_SITE_RESOLUTION_STATUS_TRANSITIONS } from '../util/site-resolution-transitions';
import { transitionSiteToCleanedOnResolution } from '../util/transition-site-to-cleaned-on-resolution.helper';
import { SiteResolutionPointsService } from './site-resolution-points.service';
import { SiteResolutionNotificationService } from './site-resolution-notification.service';
import { emitGamificationPointsCredited } from '../../../gamification/util/gamification-credit-events.util';
import type { EcoEventPointsCreditResult } from '../../../gamification/services/eco-event-points.service';

@Injectable()
export class SiteResolutionModerationService {
  private readonly logger = new Logger(SiteResolutionModerationService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly siteEventsService: SiteEventsService,
    private readonly siteHistoryWriter: SiteHistoryWriterService,
    private readonly sitesFeed: SitesFeedService,
    private readonly sitesMapQuery: SitesMapQueryService,
    private readonly sitesReporterNotification: SitesReporterNotificationService,
    private readonly resolutionPoints: SiteResolutionPointsService,
    private readonly resolutionNotifications: SiteResolutionNotificationService,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  async updateStatus(
    resolutionId: string,
    dto: UpdateSiteResolutionStatusDto,
    moderator: AuthenticatedUser,
  ): Promise<SiteResolution> {
    if (dto.status === SiteResolutionStatus.PENDING) {
      throw new BadRequestException({
        code: 'INVALID_SITE_RESOLUTION_STATUS',
        message: 'Cannot set resolution status to PENDING via moderation.',
      });
    }

    if (dto.status === SiteResolutionStatus.REJECTED && !dto.reason?.trim()) {
      throw new BadRequestException({
        code: 'RESOLUTION_REJECTION_REASON_REQUIRED',
        message: 'Reason is required when rejecting a resolution.',
      });
    }

    const resolution = await this.prisma.siteResolution.findUnique({
      where: { id: resolutionId },
      select: {
        id: true,
        siteId: true,
        status: true,
        submittedById: true,
        isReporterSubmission: true,
        mediaUrls: true,
      },
    });

    if (!resolution) {
      throw new NotFoundException({
        code: 'SITE_RESOLUTION_NOT_FOUND',
        message: `Resolution with id '${resolutionId}' was not found`,
      });
    }

    if (resolution.status === dto.status) {
      return this.prisma.siteResolution.findUniqueOrThrow({ where: { id: resolutionId } });
    }

    const allowed = ALLOWED_SITE_RESOLUTION_STATUS_TRANSITIONS[resolution.status];
    if (!allowed.includes(dto.status)) {
      throw new BadRequestException({
        code: 'INVALID_SITE_RESOLUTION_STATUS_TRANSITION',
        message: `Cannot transition resolution status from '${resolution.status}' to '${dto.status}'`,
        details: { from: resolution.status, to: dto.status, allowedTo: allowed },
      });
    }

    const now = new Date();
    const moderatorActor = { userId: moderator.userId, role: moderator.role };

    const result = await this.prisma.$transaction(async (tx) => {
      let pointsCredit: { userId: string; credit: EcoEventPointsCreditResult } | null = null;

      const updated = await tx.siteResolution.update({
        where: { id: resolutionId },
        data: {
          status: dto.status,
          moderatedAt: now,
          moderationReason: dto.reason?.trim() ?? null,
          moderatedById: moderator.userId,
        },
      });

      if (dto.status === SiteResolutionStatus.APPROVED) {
        const pointsResult = await this.resolutionPoints.creditApprovalIfEligible(tx, {
          resolution: {
            id: updated.id,
            siteId: updated.siteId,
            submittedById: updated.submittedById,
            isReporterSubmission: updated.isReporterSubmission,
            mediaUrls: updated.mediaUrls,
          },
          now,
        });
        if (updated.submittedById != null && pointsResult.credit.granted > 0) {
          pointsCredit = { userId: updated.submittedById, credit: pointsResult.credit };
        }
      }

      if (dto.status === SiteResolutionStatus.REJECTED && resolution.status === SiteResolutionStatus.APPROVED) {
        await this.resolutionPoints.debitRevokedApprovalIfNeeded(tx, {
          resolutionId,
          userId: resolution.submittedById,
        });
      }

      let siteTransition: Awaited<ReturnType<typeof transitionSiteToCleanedOnResolution>> = null;
      if (dto.status === SiteResolutionStatus.APPROVED) {
        siteTransition = await transitionSiteToCleanedOnResolution(tx, updated.siteId);
      }

      if (dto.status === SiteResolutionStatus.APPROVED) {
        await this.siteHistoryWriter.write(
          {
            siteId: updated.siteId,
            kind: SiteHistoryEntryKind.RESOLUTION_APPROVED,
            occurredAt: now,
            actor: moderatorActor,
            metadata: { resolutionId } as Prisma.InputJsonValue,
          },
          { tx, emitSse: false },
        );
      } else {
        await this.siteHistoryWriter.write(
          {
            siteId: updated.siteId,
            kind: SiteHistoryEntryKind.RESOLUTION_REJECTED,
            occurredAt: now,
            actor: moderatorActor,
            note: dto.reason?.trim() ?? null,
            metadata: { resolutionId } as Prisma.InputJsonValue,
          },
          { tx, emitSse: false },
        );
      }

      if (siteTransition != null) {
        await this.siteHistoryWriter.recordStatusChanged(
          {
            siteId: siteTransition.id,
            fromStatus: siteTransition.fromStatus,
            toStatus: siteTransition.status,
            occurredAt: siteTransition.updatedAt,
            actor: moderatorActor,
            metadata: { trigger: 'RESOLUTION_APPROVED', resolutionId } as Prisma.InputJsonValue,
          },
          tx,
        );
      }

      return { updated, siteTransition, pointsCredit };
    });

    const { updated, siteTransition, pointsCredit } = result;

    if (siteTransition != null) {
      this.siteEventsService.emitSiteUpdated(updated.siteId, {
        kind: 'status_changed',
        status: siteTransition.status,
        latitude: siteTransition.latitude,
        longitude: siteTransition.longitude,
        updatedAt: siteTransition.updatedAt,
      });
      this.sitesFeed.invalidateFeedCache('site_resolution_approved');
      this.sitesMapQuery.invalidateMapCache('site_resolution_approved', updated.siteId);
      this.sitesReporterNotification.emitSiteStatusUpdate(
        updated.siteId,
        moderator.userId,
        siteTransition.status,
        { skipRecipientIds: updated.submittedById ? [updated.submittedById] : [] },
      );
      void this.resolutionNotifications.notifySiteResolved({
        siteId: updated.siteId,
        actorUserId: moderator.userId,
        skipRecipientIds: updated.submittedById ? [updated.submittedById] : [],
      });
    }

    if (updated.submittedById != null) {
      void this.resolutionNotifications.notifySubmitter({
        submitterId: updated.submittedById,
        siteId: updated.siteId,
        resolutionId: updated.id,
        status: dto.status,
      });
    }

    if (pointsCredit != null) {
      emitGamificationPointsCredited(this.eventEmitter, pointsCredit.userId, pointsCredit.credit);
    }

    this.siteHistoryWriter.emitHistoryAppended(updated.siteId, updated.id);

    await this.audit.log({
      actorId: moderator.userId,
      action: 'SITE_RESOLUTION_STATUS_UPDATED',
      resourceType: 'SiteResolution',
      resourceId: resolutionId,
      metadata: {
        from: resolution.status,
        to: dto.status,
        siteId: updated.siteId,
        siteTransitioned: siteTransition != null,
      },
    });

    this.logger.log({
      msg: 'site_resolution_moderation_status_updated',
      resolutionId,
      fromStatus: resolution.status,
      toStatus: dto.status,
      moderatorId: moderator.userId,
      siteId: updated.siteId,
    });

    return updated;
  }
}
