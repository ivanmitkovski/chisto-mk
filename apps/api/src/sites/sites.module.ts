import { Module } from '@nestjs/common';
import { AdminEventsModule } from '../admin-events/admin-events.module';
import { AuditModule } from '../audit/audit.module';
import { ReportsModule } from '../reports/reports.module';
import { FeedRankingService } from './feed-ranking.service';
import { SiteEngagementService } from './site-engagement.service';
import { SitesController } from './sites.controller';
import { SitesService } from './sites.service';

@Module({
  imports: [AuditModule, ReportsModule, AdminEventsModule],
  controllers: [SitesController],
  providers: [SitesService, FeedRankingService, SiteEngagementService],
  exports: [SitesService, FeedRankingService],
})
export class SitesModule {}
