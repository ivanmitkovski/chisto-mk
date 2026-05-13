import { Module } from '@nestjs/common';
import { AdminRealtimeModule } from '../admin-realtime/admin-realtime.module';
import { AuditModule } from '../audit/audit.module';
import { GamificationModule } from '../gamification/gamification.module';
import { ReportsController } from './reports.controller';
import { OwnerEventsModule } from './owner-events/owner-events.module';
import { ReportCitizenQueryService } from './report-citizen-query.service';
import { ReportApprovalPointsService } from './report-approval-points.service';
import { ReportPointsService } from './report-points.service';
import { ReportSubmitPostCreateEventsService } from './report-submit-post-create-events.service';
import { ReportSubmitIdempotencyService } from './report-submit-idempotency.service';
import { ReportSubmitMediaAppendService } from './report-submit-media-append.service';
import { ReportSubmitService } from './report-submit.service';
import { ReportsService } from './reports.service';
import { ReportsModerationDetailService } from './reports-moderation-detail.service';
import { ReportsModerationListService } from './reports-moderation-list.service';
import { ReportsModerationService } from './reports-moderation.service';
import { ReportsModerationStatusService } from './reports-moderation-status.service';
import { DuplicateMergeSnapshotService } from './duplicate-merge-snapshot.service';
import { DuplicateMergeTransactionService } from './duplicate-merge-transaction.service';
import { ReportsDuplicateMergeService } from './reports-duplicate-merge.service';
import { DuplicateGroupQueryService } from './duplicates/duplicate-group-query.service';
import { DuplicateMergeSideEffectsService } from './duplicates/duplicate-merge-side-effects.service';
import { ReportSideEffectProcessorService } from './side-effects/report-side-effect-processor.service';
import { ReportCapacityService } from './report-capacity.service';
import { ReportsUploadModule } from './reports-upload.module';
import { ReportSubmitIdempotencyCleanupService } from './report-submit-idempotency-cleanup.service';
import { ReportUploadOrphanGcService } from './report-upload-orphan-gc.service';
import { NearbySiteForReportSubmitResolver } from './site-resolution/nearby-site-for-report-submit.resolver';
import { ReportsUserThrottlerGuard } from './reports-user-throttler.guard';
import { ParseCuidPipe } from '../common/pipes/parse-cuid.pipe';

@Module({
  imports: [AdminRealtimeModule, AuditModule, GamificationModule, ReportsUploadModule, OwnerEventsModule],
  controllers: [ReportsController],
  providers: [
    ReportsModerationListService,
    ReportsModerationStatusService,
    ReportsModerationDetailService,
    ReportsModerationService,
    DuplicateGroupQueryService,
    DuplicateMergeSideEffectsService,
    ReportSideEffectProcessorService,
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
    ReportSubmitService,
    ReportsService,
    ReportCapacityService,
    ReportSubmitIdempotencyCleanupService,
    ReportUploadOrphanGcService,
    ReportsUserThrottlerGuard,
    ParseCuidPipe,
  ],
  exports: [ReportsUploadModule],
})
export class ReportsModule {}
