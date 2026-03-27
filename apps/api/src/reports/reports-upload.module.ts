import { Module } from '@nestjs/common';
import { ReportsUploadService } from './reports-upload.service';

@Module({
  providers: [ReportsUploadService],
  exports: [ReportsUploadService],
})
export class ReportsUploadModule {}
