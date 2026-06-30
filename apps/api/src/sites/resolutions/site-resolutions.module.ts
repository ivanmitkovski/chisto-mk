import { Module, forwardRef } from '@nestjs/common';
import { AuditModule } from '../../audit/audit.module';
import { AdminModerationEmailModule } from '../../admin-moderation-email/admin-moderation-email.module';
import { AdminRealtimeModule } from '../../admin-realtime/admin-realtime.module';
import { GamificationModule } from '../../gamification/gamification.module';
import { ReportsUploadModule } from '../../reports/reports-upload.module';
import { StorageModule } from '../../storage/storage.module';
import { SiteHistoryModule } from '../history/site-history.module';
import { SitesAdminModule } from '../sites-admin.module';
import { SitesFeedModule } from '../sites-feed.module';
import { SitesMapModule } from '../sites-map.module';
import { SitesEngagementModule } from '../sites-engagement.module';
import { SiteResolutionQueryModule } from './site-resolution-query.module';
import { SiteResolutionsController } from './controllers/site-resolutions.controller';
import { SiteResolutionsAdminController } from './controllers/site-resolutions-admin.controller';
import { SiteResolutionUploadService } from './services/site-resolution-upload.service';
import { SiteResolutionSubmitService } from './services/site-resolution-submit.service';
import { SiteResolutionModerationService } from './services/site-resolution-moderation.service';
import { SiteResolutionPointsService } from './services/site-resolution-points.service';
import { SiteResolutionNotificationService } from './services/site-resolution-notification.service';
import { SiteCleanupEvidenceService } from './services/site-cleanup-evidence.service';
import { SiteDetailRepository } from '../repositories/site-detail.repository';

@Module({
  imports: [
    AuditModule,
    AdminModerationEmailModule,
    AdminRealtimeModule,
    GamificationModule,
    ReportsUploadModule,
    StorageModule,
    SiteHistoryModule,
    SiteResolutionQueryModule,
    forwardRef(() => SitesAdminModule),
    forwardRef(() => SitesFeedModule),
    forwardRef(() => SitesMapModule),
    SitesEngagementModule,
  ],
  controllers: [SiteResolutionsAdminController, SiteResolutionsController],
  providers: [
    SiteResolutionUploadService,
    SiteResolutionSubmitService,
    SiteResolutionModerationService,
    SiteResolutionPointsService,
    SiteResolutionNotificationService,
    SiteCleanupEvidenceService,
    SiteDetailRepository,
  ],
  exports: [
    SiteResolutionQueryModule,
    SiteResolutionSubmitService,
    SiteCleanupEvidenceService,
    SiteResolutionModerationService,
  ],
})
export class SiteResolutionsModule {}
