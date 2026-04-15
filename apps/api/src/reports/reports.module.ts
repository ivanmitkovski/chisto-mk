import { Module } from '@nestjs/common';
import { AdminEventsModule } from '../admin-events/admin-events.module';
import { AuditModule } from '../audit/audit.module';
import { ReportsController } from './reports.controller';
import { ReportsOwnerEventsService } from './reports-owner-events.service';
import { ReportsService } from './reports.service';
import { ReportsModerationService } from './reports-moderation.service';
import { ReportsDuplicateMergeService } from './reports-duplicate-merge.service';
import { ReportCapacityService } from './report-capacity.service';
import { ReportsUploadModule } from './reports-upload.module';
import { ReportSubmitIdempotencyCleanupService } from './report-submit-idempotency-cleanup.service';

@Module({
  imports: [AdminEventsModule, AuditModule, ReportsUploadModule],
  controllers: [ReportsController],
  providers: [
    ReportsModerationService,
    ReportsDuplicateMergeService,
    ReportsService,
    ReportCapacityService,
    ReportsOwnerEventsService,
    ReportSubmitIdempotencyCleanupService,
  ],
  exports: [ReportsUploadModule],
})
export class ReportsModule {}
