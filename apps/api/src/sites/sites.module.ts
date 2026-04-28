import { Module } from '@nestjs/common';
import { AdminEventsModule } from '../admin-events/admin-events.module';
import { AuditModule } from '../audit/audit.module';
import { ReportsUploadModule } from '../reports/reports-upload.module';
import { FeedRankingService } from './feed-ranking.service';
import { SiteEngagementService } from './site-engagement.service';
import { SiteCommentsService } from './site-comments.service';
import { SitesAdminService } from './sites-admin.service';
import { SitesController } from './sites.controller';
import { SitesDetailService } from './sites-detail.service';
import { SitesFeedService } from './sites-feed.service';
import { SitesMapQueryService } from './sites-map-query.service';
import { SitesMediaService } from './sites-media.service';
import { SitesService } from './sites.service';
import { SiteDetailRepository } from './repositories/site-detail.repository';
import { SiteMediaRepository } from './repositories/site-media.repository';

@Module({
  imports: [AuditModule, ReportsUploadModule, AdminEventsModule],
  controllers: [SitesController],
  providers: [
    SitesMapQueryService,
    SitesFeedService,
    SitesDetailService,
    SitesMediaService,
    SitesAdminService,
    SitesService,
    FeedRankingService,
    SiteEngagementService,
    SiteCommentsService,
    SiteDetailRepository,
    SiteMediaRepository,
  ],
  exports: [SitesService, FeedRankingService],
})
export class SitesModule {}
