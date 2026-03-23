import { Module } from '@nestjs/common';
import { ReportsController } from './reports.controller';
import { ReportsService } from './reports.service';
import { ReportsUploadService } from './reports-upload.service';

@Module({
  controllers: [ReportsController],
  providers: [ReportsService, ReportsUploadService],
  exports: [ReportsUploadService],
})
export class ReportsModule {}
