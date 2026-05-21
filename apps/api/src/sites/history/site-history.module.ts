import { Module } from '@nestjs/common';
import { AdminRealtimeModule } from '../../admin-realtime/admin-realtime.module';
import { SiteHistoryAdminController } from './site-history-admin.controller';
import { SiteHistoryController } from './site-history.controller';
import { SiteHistoryQueryService } from './site-history-query.service';
import { SiteHistoryWriterService } from './site-history-writer.service';
import { SiteHistoryReportRecorderService } from './site-history-report-recorder.service';
import { SiteHistoryEventRecorderService } from './site-history-event-recorder.service';

@Module({
  imports: [AdminRealtimeModule],
  controllers: [SiteHistoryController, SiteHistoryAdminController],
  providers: [
    SiteHistoryWriterService,
    SiteHistoryReportRecorderService,
    SiteHistoryEventRecorderService,
    SiteHistoryQueryService,
  ],
  exports: [
    SiteHistoryWriterService,
    SiteHistoryReportRecorderService,
    SiteHistoryEventRecorderService,
    SiteHistoryQueryService,
  ],
})
export class SiteHistoryModule {}
