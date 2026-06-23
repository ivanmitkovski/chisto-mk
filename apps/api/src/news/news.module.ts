import { Module } from '@nestjs/common';
import { AuditModule } from '../audit/audit.module';
import { StorageModule } from '../storage/storage.module';
import { AdminNewsController } from './controllers/admin-news.controller';
import { PublicNewsController } from './controllers/public-news.controller';
import { NewsMediaSignedUrlService } from './services/news-media-signed-url.service';
import { NewsMediaUploadService } from './services/news-media-upload.service';
import { NewsPostsQueryService } from './services/news-posts-query.service';
import { NewsPostsService } from './services/news-posts.service';
import { NewsPostsDeleteService } from './services/news-posts-delete.service';
import { NewsRevalidateService } from './services/news-revalidate.service';

@Module({
  imports: [StorageModule, AuditModule],
  controllers: [PublicNewsController, AdminNewsController],
  providers: [
    NewsPostsService,
    NewsPostsDeleteService,
    NewsPostsQueryService,
    NewsMediaUploadService,
    NewsMediaSignedUrlService,
    NewsRevalidateService,
  ],
  exports: [NewsPostsQueryService, NewsPostsService],
})
export class NewsModule {}
