import { Module } from '@nestjs/common';
import { AdminEventsModule } from '../admin-events/admin-events.module';
import { AuditModule } from '../audit/audit.module';
import { ReportsController } from './reports.controller';
import { ReportsOwnerEventsService } from './reports-owner-events.service';
import { ReportsService } from './reports.service';
import { ReportsUploadService } from './reports-upload.service';

@Module({
  imports: [AdminEventsModule, AuditModule],
  controllers: [ReportsController],
  providers: [ReportsService, ReportsUploadService, ReportsOwnerEventsService],
  exports: [ReportsUploadService],
})
export class ReportsModule {}
