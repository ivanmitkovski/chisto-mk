import { Module } from '@nestjs/common';
import { AdminRealtimeModule } from '../admin-realtime/admin-realtime.module';
import { AdminModerationEmailModule } from '../admin-moderation-email/admin-moderation-email.module';
import { AuditModule } from '../audit/audit.module';
import { SiteHistoryModule } from '../sites/history/site-history.module';
import { SiteHistoryWriterService } from '../sites/history/site-history-writer.service';
import { GamificationModule } from '../gamification/gamification.module';
import { ReportsController } from './controllers/reports.controller';
import { OwnerEventsModule } from './owner-events/owner-events.module';
import { ReportCitizenQueryService } from './services/report-citizen-query.service';
import { ReportApprovalPointsService } from './services/report-approval-points.service';
import { ReportPointsService } from './services/report-points.service';
import { ReportSubmitPostCreateEventsService } from './services/report-submit-post-create-events.service';
import { ReportSubmitIdempotencyService } from './services/report-submit-idempotency.service';
import { ReportSubmitMediaAppendService } from './services/report-submit-media-append.service';
import { ReportSubmitPersistenceService } from './services/report-submit-persistence.service';
import { ReportSubmitService } from './services/report-submit.service';
import { ReportsService } from './services/reports.service';
import { ReportsModerationDetailService } from './services/reports-moderation-detail.service';
import { ReportsModerationListService } from './services/reports-moderation-list.service';
import { ReportsModerationService } from './services/reports-moderation.service';
import { ReportsModerationStatusService } from './services/reports-moderation-status.service';
import { ReportsModerationAssignService } from './services/reports-moderation-assign.service';
import { ReportViewerPresenceService } from './services/report-viewer-presence.service';
import { DuplicateMergeSnapshotService } from './services/duplicate-merge-snapshot.service';
import { DuplicateMergeTransactionService } from './services/duplicate-merge-transaction.service';
import { ReportsDuplicateMergeService } from './services/reports-duplicate-merge.service';
import { DuplicateGroupQueryService } from './duplicates/duplicate-group-query.service';
import { DuplicateMergeSideEffectsService } from './duplicates/duplicate-merge-side-effects.service';
import { ReportSideEffectProcessorService } from './side-effects/report-side-effect-processor.service';
import { ReportSideEffectRetryService } from './side-effects/report-side-effect-retry.service';
import { ReportSideEffectQueryService } from './side-effects/report-side-effect-query.service';
import { ReportCapacityService } from './services/report-capacity.service';
import { ReportsUploadModule } from './reports-upload.module';
import { ReportSubmitIdempotencyCleanupService } from './services/report-submit-idempotency-cleanup.service';
import { ReportUploadOrphanGcService } from './services/report-upload-orphan-gc.service';
import { NearbySiteForReportSubmitResolver } from './site-resolution/nearby-site-for-report-submit.resolver';
import { ReportsUserThrottlerGuard } from './guards/reports-user-throttler.guard';
import { SITE_HISTORY_WRITER } from './ports/site-history-writer.port';

@Module({
  imports: [
    AdminRealtimeModule,
    AdminModerationEmailModule,
    AuditModule,
    GamificationModule,
    ReportsUploadModule,
    OwnerEventsModule,
    SiteHistoryModule,
  ],
  controllers: [ReportsController],
  providers: [
    ReportsModerationListService,
    ReportsModerationStatusService,
    ReportsModerationAssignService,
    ReportViewerPresenceService,
    ReportsModerationDetailService,
    ReportsModerationService,
    DuplicateGroupQueryService,
    DuplicateMergeSideEffectsService,
    ReportSideEffectProcessorService,
    ReportSideEffectRetryService,
    ReportSideEffectQueryService,
    DuplicateMergeSnapshotService,
    DuplicateMergeTransactionService,
    ReportsDuplicateMergeService,
    ReportCitizenQueryService,
    ReportApprovalPointsService,
    ReportPointsService,
    ReportSubmitPostCreateEventsService,
    NearbySiteForReportSubmitResolver,
    ReportSubmitIdempotencyService,
    ReportSubmitMediaAppendService,
    ReportSubmitPersistenceService,
    ReportSubmitService,
    ReportsService,
    ReportCapacityService,
    ReportSubmitIdempotencyCleanupService,
    ReportUploadOrphanGcService,
    ReportsUserThrottlerGuard,
    {
      provide: SITE_HISTORY_WRITER,
      useExisting: SiteHistoryWriterService,
    },
  ],
  exports: [ReportsUploadModule, ReportSideEffectQueryService],
})
export class ReportsModule {}
