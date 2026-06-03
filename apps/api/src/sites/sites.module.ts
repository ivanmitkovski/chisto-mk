import { Module } from '@nestjs/common';
import { AuditModule } from '../audit/audit.module';
import { AdminRealtimeModule } from '../admin-realtime/admin-realtime.module';
import { FeatureFlagsModule } from '../feature-flags/feature-flags.module';
import { SiteHistoryModule } from './history/site-history.module';
import { SitesController } from './controllers/sites.controller';
import { SiteLifecycleFromEventsService } from './services/site-lifecycle-from-events.service';
import { SitesAdminModule } from './sites-admin.module';
import { SitesDetailModule } from './sites-detail.module';
import { SitesFeedModule } from './sites-feed.module';
import { SitesMapModule } from './sites-map.module';
import { SitesEngagementModule } from './sites-engagement.module';

@Module({
  imports: [
    AuditModule,
    AdminRealtimeModule,
    FeatureFlagsModule,
    SiteHistoryModule,
    SitesAdminModule,
    SitesFeedModule,
    SitesMapModule,
    SitesDetailModule,
    SitesEngagementModule,
  ],
  controllers: [SitesController],
  providers: [SiteLifecycleFromEventsService],
  exports: [
    SitesFeedModule,
    SiteHistoryModule,
    SiteLifecycleFromEventsService,
    SitesMapModule,
    SitesEngagementModule,
  ],
})
export class SitesModule {}
