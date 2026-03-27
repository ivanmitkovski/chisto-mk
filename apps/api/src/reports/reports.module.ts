import { Module } from '@nestjs/common';
import { AdminEventsModule } from '../admin-events/admin-events.module';
import { AuditModule } from '../audit/audit.module';
import { ReportsController } from './reports.controller';
import { ReportsOwnerEventsService } from './reports-owner-events.service';
import { ReportsService } from './reports.service';
import { ReportsUploadModule } from './reports-upload.module';

@Module({
  imports: [AdminEventsModule, AuditModule, ReportsUploadModule],
  controllers: [ReportsController],
  providers: [ReportsService, ReportsOwnerEventsService],
  exports: [ReportsUploadModule],
})
export class ReportsModule {}
