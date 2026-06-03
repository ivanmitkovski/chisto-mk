import { Inject, Injectable, Logger } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { NotificationType } from '../../prisma-client';
import { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { CreateReportWithLocationDto } from '../dto/create-report-with-location.dto';
import { ReportSubmitResponseDto } from '../dto/report-submit-response.dto';
import { ReportSubmitPostCreateEventsService } from './report-submit-post-create-events.service';
import { ReportSubmitIdempotencyService } from './report-submit-idempotency.service';
import { ReportSubmitMediaAppendService } from './report-submit-media-append.service';
import { ReportSubmitPersistenceService } from './report-submit-persistence.service';
import { ReportsOwnerEventsService } from './reports-owner-events.service';
import type { ReportSubmitLocale } from '../util/report-locale.util';
import { ObservabilityStore } from '../../observability/observability.store';
import { ReportsUploadService } from './reports-upload.service';
import { reportReceivedUserCopy } from '../../notifications/util/notification-templates';
import { SITE_HISTORY_WRITER, type SiteHistoryWriterPort } from '../ports/site-history-writer.port';

@Injectable()
export class ReportSubmitService {
  private readonly logger = new Logger(ReportSubmitService.name);

  constructor(
    private readonly postCreateEvents: ReportSubmitPostCreateEventsService,
    private readonly reportsOwnerEventsService: ReportsOwnerEventsService,
    private readonly reportsUpload: ReportsUploadService,
    private readonly idempotency: ReportSubmitIdempotencyService,
    private readonly mediaAppend: ReportSubmitMediaAppendService,
    private readonly persistence: ReportSubmitPersistenceService,
    private readonly eventEmitter: EventEmitter2,
    @Inject(SITE_HISTORY_WRITER) private readonly siteHistoryWriter: SiteHistoryWriterPort,
  ) {}

  async createWithLocation(
    user: AuthenticatedUser,
    dto: CreateReportWithLocationDto,
    headerIdempotencyKey?: string | string[],
    locale: ReportSubmitLocale = 'mk',
    requestId?: string,
  ): Promise<ReportSubmitResponseDto> {
    const startedAt = Date.now();
    const trimmedIdem = this.idempotency.parseIdempotencyKeyHeader(headerIdempotencyKey);
    if (trimmedIdem) {
      const replay = await this.idempotency.tryReplayFromIdempotencyKey(user.userId, trimmedIdem);
      if (replay) {
        ObservabilityStore.recordReportSubmit('success', Date.now() - startedAt);
        this.logger.log(
          JSON.stringify({
            scope: 'report_submit',
            outcome: 'idempotent_replay',
            requestId: requestId ?? null,
            reportId: replay.reportId,
            durationMs: Date.now() - startedAt,
          }),
        );
        return replay;
      }
    }

    try {
      this.reportsUpload.assertReportMediaUrlsFromOurBucket(dto.mediaUrls);
      const result = await this.persistence.persistReportWithLocation(user, dto, {
        trimmedIdem: trimmedIdem ?? null,
        locale,
      });

      if (trimmedIdem) {
        this.reportsOwnerEventsService.emit(user.userId, result.reportId, 'report_submit_queued', {
          kind: 'submit_queued',
          idempotencyKey: trimmedIdem,
        });
      }

      this.siteHistoryWriter.emitHistoryAppended(result.siteId, result.reportId);

      this.postCreateEvents.emit({
        userId: user.userId,
        reportId: result.reportId,
        siteId: result.siteId,
        isNewSite: result.isNewSite,
        notificationId: result.notificationId,
        notificationTitle: result.notificationTitle,
        siteUpdatedAt: result.siteUpdatedAt,
        latitude: dto.latitude,
        longitude: dto.longitude,
      });

      const inboxLocale = locale === 'en' ? 'en' : 'mk';
      const receivedCopy = reportReceivedUserCopy(inboxLocale, result.reportNumber);
      this.eventEmitter.emit('notification.send', {
        recipientUserIds: [user.userId],
        title: receivedCopy.title,
        body: receivedCopy.body,
        type: NotificationType.SYSTEM,
        data: {
          kind: 'report_received',
          reportId: result.reportId,
          siteId: result.siteId,
          reportNumber: result.reportNumber,
        },
        threadKey: `report_received:${result.reportId}`,
        groupKey: `SYSTEM:report_received:${result.siteId}`,
      });

      ObservabilityStore.recordReportSubmit('success', Date.now() - startedAt);
      this.logger.log(
        JSON.stringify({
          scope: 'report_submit',
          outcome: 'success',
          requestId: requestId ?? null,
          reportId: result.reportId,
          siteId: result.siteId,
          isNewSite: result.isNewSite,
          idempotencyKey: trimmedIdem ?? null,
          durationMs: Date.now() - startedAt,
        }),
      );

      return {
        reportId: result.reportId,
        reportNumber: result.reportNumber,
        siteId: result.siteId,
        isNewSite: result.isNewSite,
        pointsAwarded: 0,
      };
    } catch (err) {
      ObservabilityStore.recordReportSubmit('error');
      this.logger.warn(
        JSON.stringify({
          scope: 'report_submit',
          outcome: 'error',
          requestId: requestId ?? null,
          idempotencyKey: trimmedIdem ?? null,
          durationMs: Date.now() - startedAt,
        }),
      );
      throw err;
    }
  }

  appendMedia(reportId: string, userId: string, urls: string[]): Promise<void> {
    return this.mediaAppend.appendMedia(reportId, userId, urls);
  }
}
