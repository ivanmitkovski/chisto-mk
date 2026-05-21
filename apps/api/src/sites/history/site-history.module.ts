import { Module } from '@nestjs/common';
import { AdminRealtimeModule } from '../../admin-realtime/admin-realtime.module';
import { SiteHistoryAdminController } from './site-history-admin.controller';
import { SiteHistoryController } from './site-history.controller';
import { SiteHistoryQueryService } from './site-history-query.service';
import { SiteHistoryWriterService } from './site-history-writer.service';

@Module({
  imports: [AdminRealtimeModule],
  controllers: [SiteHistoryController, SiteHistoryAdminController],
  providers: [SiteHistoryWriterService, SiteHistoryQueryService],
  exports: [SiteHistoryWriterService, SiteHistoryQueryService],
})
export class SiteHistoryModule {}
