import { Inject, Injectable } from '@nestjs/common';
import {
  AdminNotificationCategory,
  AdminNotificationTone,
  Prisma,
  ReportCleanupEffort,
} from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';
import { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { CreateReportWithLocationDto } from '../dto/create-report-with-location.dto';
import { ReportCapacityService } from './report-capacity.service';
import { NearbySiteForReportSubmitResolver } from '../site-resolution/nearby-site-for-report-submit.resolver';
import { parseReportCleanupEffort } from '../util/report-cleanup-effort';
import { adminSubmitNotificationCopy, getReportNumber } from '../util/report-copy.helpers';
import type { ReportSubmitLocale } from '../util/report-locale.util';
import { SiteHistoryReportRecorderService } from '../../sites/history/site-history-report-recorder.service';
import {
  SITE_HISTORY_WRITER,
  type SiteHistoryWriterPort,
} from '../ports/site-history-writer.port';

export type ReportSubmitPersistenceResult = {
  reportId: string;
  reportNumber: string;
  siteId: string;
  isNewSite: boolean;
  pointsAwarded: 0;
  siteUpdatedAt: Date | null;
  notificationId: string;
  notificationTitle: string;
};

@Injectable()
export class ReportSubmitPersistenceService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly reportCapacity: ReportCapacityService,
    private readonly nearbySiteResolver: NearbySiteForReportSubmitResolver,
    @Inject(SITE_HISTORY_WRITER) private readonly siteHistoryWriter: SiteHistoryWriterPort,
    private readonly siteHistoryReportRecorder: SiteHistoryReportRecorderService,
  ) {}

  async persistReportWithLocation(
    user: AuthenticatedUser,
    dto: CreateReportWithLocationDto,
    opts: {
      trimmedIdem: string | null;
      locale: ReportSubmitLocale;
    },
  ): Promise<ReportSubmitPersistenceResult> {
    const submitLocale = opts.locale;
    const { latitude, longitude, title, description, mediaUrls, category, severity, address } = dto;
    const trimmedAddress = address?.trim() || null;
    const cleanupEffortParsed: ReportCleanupEffort | null = parseReportCleanupEffort(
      dto.cleanupEffort,
    );

    return this.prisma.$transaction(async (tx) => {
      await this.reportCapacity.spendWithinTransaction(tx, user.userId, new Date());

      const primaryReport = await this.nearbySiteResolver.resolveEarliestReportAnchor(
        latitude,
        longitude,
        tx,
      );
      const targetSiteId = primaryReport?.siteId ?? null;

      let siteId: string;
      let isNewSite: boolean;
      let siteUpdatedAt: Date | null = null;

      if (targetSiteId) {
        siteId = targetSiteId;
        isNewSite = false;
        if (trimmedAddress) {
          await tx.site.updateMany({
            where: { id: targetSiteId, address: null },
            data: { address: trimmedAddress },
          });
        }
      } else {
        const newSite = await tx.site.create({
          data: {
            latitude,
            longitude,
            address: trimmedAddress,
            description: null,
          },
        });
        siteId = newSite.id;
        isNewSite = true;
        siteUpdatedAt = newSite.updatedAt;
        await this.siteHistoryWriter.recordSiteCreated(
          {
            siteId,
            occurredAt: newSite.createdAt,
            actor: { userId: user.userId, role: user.role },
          },
          tx,
        );
      }

      const newReport = await tx.report.create({
        data: {
          siteId,
          title: title.trim(),
          description: description?.trim() || null,
          mediaUrls: mediaUrls ?? [],
          reporterId: user.userId,
          potentialDuplicateOfId: primaryReport?.id ?? null,
          category: category ?? null,
          severity: severity ?? null,
          cleanupEffort: cleanupEffortParsed,
        },
      });

      await this.siteHistoryReportRecorder.recordReportSubmitted(
        {
          siteId,
          reportId: newReport.id,
          occurredAt: newReport.createdAt,
          actor: { userId: user.userId, role: user.role },
        },
        tx,
      );

      const reportNumber = getReportNumber(newReport);
      const notifCopy = adminSubmitNotificationCopy({
        locale: submitLocale,
        isNewSite,
        reportNumber,
      });

      const notification = await tx.adminNotification.create({
        data: {
          title: notifCopy.title,
          message: notifCopy.message,
          timeLabel: notifCopy.timeLabel,
          tone: AdminNotificationTone.info,
          category: AdminNotificationCategory.reports,
          href: `/dashboard/reports?reportId=${newReport.id}`,
          messageTemplateKey: isNewSite ? 'reports.submitted.new_site' : 'reports.submitted.co_report',
          messageTemplateParams: { reportNumber } as Prisma.InputJsonValue,
        },
      });

      if (opts.trimmedIdem) {
        await tx.reportSubmitIdempotency.create({
          data: {
            userId: user.userId,
            key: opts.trimmedIdem,
            reportId: newReport.id,
          },
        });
      }

      return {
        reportId: newReport.id,
        reportNumber: getReportNumber(newReport),
        siteId,
        isNewSite,
        pointsAwarded: 0 as const,
        siteUpdatedAt,
        notificationId: notification.id,
        notificationTitle: notification.title,
      };
    });
  }
}
