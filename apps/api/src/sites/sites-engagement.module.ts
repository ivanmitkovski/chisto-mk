import { Module, forwardRef } from '@nestjs/common';
import { AuditModule } from '../audit/audit.module';
import { ModerationModule } from '../moderation/moderation.module';
import { ReportsUploadModule } from '../reports/reports-upload.module';
import { SiteHistoryModule } from './history/site-history.module';
import { SiteCommentsCountModule } from './site-comments-count.module';
import { SiteBookmarkService } from './services/site-bookmark.service';
import { SiteEngagementService } from './services/site-engagement.service';
import { SiteShareLinkService } from './services/site-share-link.service';
import { SiteUpvoteService } from './services/site-upvote.service';
import { SiteCommentsListService } from './services/site-comments-list.service';
import { SiteCommentsMutationsService } from './services/site-comments-mutations.service';
import { SiteCommentsService } from './services/site-comments.service';
import { SitesCommentsController } from './controllers/sites-comments.controller';
import { SitesEngagementController } from './controllers/sites-engagement.controller';
import { SitesDetailService } from './services/sites-detail.service';
import { SitesMediaService } from './services/sites-media.service';
import { SitesEngagementSnapshotService } from './services/sites-engagement-snapshot.service';
import { SitesReporterNotificationService } from './services/sites-reporter-notification.service';
import { SitesEngagementActionsService } from './services/sites-engagement-actions.service';
import { SitesSiteUpvotesListService } from './services/sites-site-upvotes-list.service';
import { SiteCoReportersListService } from './services/site-co-reporters-list.service';
import { SiteDetailRepository } from './repositories/site-detail.repository';
import { SiteMediaRepository } from './repositories/site-media.repository';
import { SiteUpvotesRepository } from './repositories/site-upvotes.repository';
import { SitesFeedModule } from './sites-feed.module';

@Module({
  imports: [
    AuditModule,
    ReportsUploadModule,
    ModerationModule,
    SiteHistoryModule,
    SiteCommentsCountModule,
    forwardRef(() => SitesFeedModule),
  ],
  controllers: [SitesCommentsController, SitesEngagementController],
  providers: [
    SitesDetailService,
    SitesMediaService,
    SitesSiteUpvotesListService,
    SiteCoReportersListService,
    SitesEngagementSnapshotService,
    SitesReporterNotificationService,
    SitesEngagementActionsService,
    SiteUpvoteService,
    SiteBookmarkService,
    SiteShareLinkService,
    SiteEngagementService,
    SiteCommentsListService,
    SiteCommentsMutationsService,
    SiteCommentsService,
    SiteDetailRepository,
    SiteMediaRepository,
    SiteUpvotesRepository,
  ],
  exports: [SitesDetailService, SitesMediaService, SiteEngagementService, SiteCoReportersListService, SiteHistoryModule, SitesReporterNotificationService],
})
export class SitesEngagementModule {}
