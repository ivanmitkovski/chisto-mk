import { Module } from '@nestjs/common';
import { AdminEventsModule } from '../admin-events/admin-events.module';
import { AuditModule } from '../audit/audit.module';
import { ReportsController } from './reports.controller';
import { ReportsService } from './reports.service';
import { ReportsUploadService } from './reports-upload.service';

@Module({
  imports: [AdminEventsModule, AuditModule],
  controllers: [ReportsController],
  providers: [ReportsService, ReportsUploadService],
  exports: [ReportsUploadService],
})
export class ReportsModule {}
