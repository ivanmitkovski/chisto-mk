import { Module } from '@nestjs/common';
import { ReportsUploadModule } from '../../reports/reports-upload.module';
import { StorageModule } from '../../storage/storage.module';
import { SiteResolutionQueryService } from './services/site-resolution-query.service';
import { SiteResolutionUploadService } from './services/site-resolution-upload.service';

/** Lightweight module for viewer resolution lookups without resolution write/admin deps. */
@Module({
  imports: [ReportsUploadModule, StorageModule],
  providers: [SiteResolutionUploadService, SiteResolutionQueryService],
  exports: [SiteResolutionQueryService],
})
export class SiteResolutionQueryModule {}
