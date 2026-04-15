import { Module } from '@nestjs/common';
import { AdminEventsModule } from '../admin-events/admin-events.module';
import { AuditModule } from '../audit/audit.module';
import { ReportsUploadModule } from '../reports/reports-upload.module';
import { FeedRankingService } from './feed-ranking.service';
import { SiteEngagementService } from './site-engagement.service';
import { SiteCommentsService } from './site-comments.service';
import { SitesController } from './sites.controller';
import { SitesMapQueryService } from './sites-map-query.service';
import { SitesService } from './sites.service';

@Module({
  imports: [AuditModule, ReportsUploadModule, AdminEventsModule],
  controllers: [SitesController],
  providers: [
    SitesMapQueryService,
    SitesService,
    FeedRankingService,
    SiteEngagementService,
    SiteCommentsService,
  ],
  exports: [SitesService, FeedRankingService],
})
export class SitesModule {}
