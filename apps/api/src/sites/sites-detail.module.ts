import { Module } from '@nestjs/common';
import { SitesDetailController } from './controllers/sites-detail.controller';
import { SitesAdminModule } from './sites-admin.module';
import { SitesEngagementModule } from './sites-engagement.module';
import { SiteResolutionsModule } from './resolutions/site-resolutions.module';

/** Loaded after {@link SitesMapModule} so `/sites/map` is not captured by `GET /sites/:id`. Admin resolution routes live under `/sites/admin/resolutions`. */
@Module({
  imports: [SitesAdminModule, SitesEngagementModule, SiteResolutionsModule],
  controllers: [SitesDetailController],
})
export class SitesDetailModule {}
