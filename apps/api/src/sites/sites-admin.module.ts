import { Module, forwardRef } from '@nestjs/common';
import { AdminRealtimeModule } from '../admin-realtime/admin-realtime.module';
import { AuditModule } from '../audit/audit.module';
import { SiteHistoryModule } from './history/site-history.module';
import { SitesAdminBulkService } from './services/sites-admin-bulk.service';
import { SitesAdminService } from './services/sites-admin.service';
import { SitesFeedModule } from './sites-feed.module';
import { SitesMapModule } from './sites-map.module';

@Module({
  imports: [
    AuditModule,
    AdminRealtimeModule,
    SiteHistoryModule,
    forwardRef(() => SitesFeedModule),
    forwardRef(() => SitesMapModule),
  ],
  providers: [SitesAdminService, SitesAdminBulkService],
  exports: [SitesAdminService, SitesAdminBulkService],
})
export class SitesAdminModule {}
