import { Module } from '@nestjs/common';
import { SitesDetailController } from './controllers/sites-detail.controller';
import { SitesAdminModule } from './sites-admin.module';
import { SitesEngagementModule } from './sites-engagement.module';

/** Loaded after {@link SitesMapModule} so `/sites/map` is not captured by `GET /sites/:id`. */
@Module({
  imports: [SitesAdminModule, SitesEngagementModule],
  controllers: [SitesDetailController],
})
export class SitesDetailModule {}
