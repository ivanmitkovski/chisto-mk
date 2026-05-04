import { Module } from '@nestjs/common';
import { AdminEventsModule } from '../admin-events/admin-events.module';
import { AuditModule } from '../audit/audit.module';
import { GamificationModule } from '../gamification/gamification.module';
import { ReportsController } from './reports.controller';
import { OwnerEventsModule } from './owner-events/owner-events.module';
import { ReportCitizenQueryService } from './report-citizen-query.service';
import { ReportApprovalPointsService } from './report-approval-points.service';
import { ReportPointsService } from './report-points.service';
import { ReportSubmitPostCreateEventsService } from './report-submit-post-create-events.service';
import { ReportSubmitService } from './report-submit.service';
import { ReportsService } from './reports.service';
import { ReportsModerationService } from './reports-moderation.service';
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
  imports: [AdminEventsModule, AuditModule, GamificationModule, ReportsUploadModule, OwnerEventsModule],
  controllers: [ReportsController],
  providers: [
    ReportsModerationService,
    DuplicateGroupQueryService,
    DuplicateMergeSideEffectsService,
    ReportSideEffectProcessorService,
    ReportsDuplicateMergeService,
    ReportCitizenQueryService,
    ReportApprovalPointsService,
    ReportPointsService,
    ReportSubmitPostCreateEventsService,
    NearbySiteForReportSubmitResolver,
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
