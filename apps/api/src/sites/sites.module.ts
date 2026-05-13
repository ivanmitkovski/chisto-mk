import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { AdminRealtimeModule } from '../admin-realtime/admin-realtime.module';
import { AuditModule } from '../audit/audit.module';
import { ReportsUploadModule } from '../reports/reports-upload.module';
import { FeedRankingService } from './feed-ranking.service';
import { SiteBookmarkService } from './site-bookmark.service';
import { SiteEngagementService } from './site-engagement.service';
import { SiteShareLinkService } from './site-share-link.service';
import { SiteUpvoteService } from './site-upvote.service';
import { SiteCommentsListService } from './site-comments-list.service';
import { SiteCommentsMutationsService } from './site-comments-mutations.service';
import { SiteCommentsService } from './site-comments.service';
import { SitesAdminService } from './sites-admin.service';
import { SitesController } from './sites.controller';
import { SitesCommentsController } from './sites-comments.controller';
import { SitesDetailController } from './sites-detail.controller';
import { SitesEngagementController } from './sites-engagement.controller';
import { SitesMapController } from './sites-map.controller';
import { SitesDetailService } from './sites-detail.service';
import { SitesFeedService } from './sites-feed.service';
import { SitesFeedCandidatesService } from './sites-feed-candidates.service';
import { SitesFeedEnrichmentService } from './sites-feed-enrichment.service';
import { SitesFeedQueryService } from './sites-feed-query.service';
import { SitesFeedCacheService } from './sites-feed-cache.service';
import { SitesFeedPreferencesService } from './sites-feed-preferences.service';
import { SitesFeedTrackingService } from './sites-feed-tracking.service';
import { SitesMapQueryService } from './sites-map-query.service';
import { SitesMediaService } from './sites-media.service';
import { SitesEngagementSnapshotService } from './sites-engagement-snapshot.service';
import { SitesMapAdminTimelineService } from './sites-map-admin-timeline.service';
import { SitesReporterNotificationService } from './sites-reporter-notification.service';
import { SitesEngagementActionsService } from './sites-engagement-actions.service';
import { SitesMapFacadeService } from './sites-map-facade.service';
import { SitesSiteUpvotesListService } from './sites-site-upvotes-list.service';
import { SiteDetailRepository } from './repositories/site-detail.repository';
import { SiteMediaRepository } from './repositories/site-media.repository';
import { SiteUpvotesRepository } from './repositories/site-upvotes.repository';
import { FeedV2Service } from './feed/feed-v2.service';
import { AssignmentService } from './feed/experiments/assignment.service';
import { UserStateRepository } from './feed/features/user-state.repository';
import { SiteFeatureRepository } from './feed/features/site-feature.repository';
import { FeatureExtractor } from './feed/features/feature-extractor';
import { RedisFeedStateAdapter } from './feed/features/redis-feed-state.adapter';
import { ModelRegistryClient } from './feed/ranker/model-registry.client';
import { RulesFallbackRanker } from './feed/ranker/rules-fallback-ranker';
import { OnnxRanker } from './feed/ranker/onnx-ranker';
import { PersonalizationRerank } from './feed/rerank/personalization-rerank';
import { DiversityRerank } from './feed/rerank/diversity-rerank';
import { PolicyRerank } from './feed/rerank/policy-rerank';
import { CandidateGenerator } from './feed/candidates/candidate-generator';
import { GeoRetriever } from './feed/candidates/geo.retriever';
import { FreshnessRetriever } from './feed/candidates/freshness.retriever';
import { EngagementRetriever } from './feed/candidates/engagement.retriever';
import { PersonalRetriever } from './feed/candidates/personal.retriever';
import { MapRateLimitGuard } from './http/map-rate-limit.guard';
import { MapCacheService } from './map/map-cache.service';
import { MapQueryValidatorService } from './map/map-query-validator.service';
import { MapResponseProjectorService } from './map/map-response-projector.service';
import { MapSiteRepositoryAggregatesService } from './map/map-site-repository-aggregates.service';
import { MapSiteRepositoryService } from './map/map-site-repository.service';
import { MapSiteRepositorySitesService } from './map/map-site-repository-sites.service';
import { MapObservabilityService } from './map/map-observability.service';
import { MapProjectionDiffService } from './map/map-projection-diff.service';
import { MapProjectionUpdaterService } from './map/map-projection-updater.service';
import { MapProjectionWriterService } from './map/map-projection-writer.service';
import { MapLifecycleCronService } from './map/map-lifecycle-cron.service';
import { MapMvtTilesFallbackService } from './map/map-mvt-tiles-fallback.service';
import { MapMvtTilesPostgisService } from './map/map-mvt-tiles-postgis.service';
import { MapMvtTilesService } from './map/map-mvt-tiles.service';
import { SitesMapSearchQueryService } from './sites-map-search-query.service';
import { SitesSearchService } from './sites-search.service';

@Module({
  imports: [ConfigModule, AuditModule, ReportsUploadModule, AdminRealtimeModule],
  controllers: [
    SitesMapController,
    SitesController,
    SitesDetailController,
    SitesCommentsController,
    SitesEngagementController,
  ],
  providers: [
    SitesMapQueryService,
    MapCacheService,
    MapQueryValidatorService,
    MapResponseProjectorService,
    MapSiteRepositorySitesService,
    MapSiteRepositoryAggregatesService,
    MapSiteRepositoryService,
    MapObservabilityService,
    MapProjectionDiffService,
    MapProjectionWriterService,
    MapProjectionUpdaterService,
    MapLifecycleCronService,
    MapMvtTilesPostgisService,
    MapMvtTilesFallbackService,
    MapMvtTilesService,
    SitesMapSearchQueryService,
    SitesSearchService,
    SitesFeedCacheService,
    SitesFeedPreferencesService,
    SitesFeedTrackingService,
    SitesFeedCandidatesService,
    SitesFeedEnrichmentService,
    SitesFeedQueryService,
    SitesFeedService,
    SitesDetailService,
    SitesMediaService,
    SitesAdminService,
    SitesMapAdminTimelineService,
    SitesSiteUpvotesListService,
    SitesEngagementSnapshotService,
    SitesReporterNotificationService,
    SitesMapFacadeService,
    SitesEngagementActionsService,
    FeedRankingService,
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
    FeedV2Service,
    AssignmentService,
    UserStateRepository,
    RedisFeedStateAdapter,
    SiteFeatureRepository,
    FeatureExtractor,
    ModelRegistryClient,
    RulesFallbackRanker,
    OnnxRanker,
    PersonalizationRerank,
    DiversityRerank,
    PolicyRerank,
    CandidateGenerator,
    GeoRetriever,
    FreshnessRetriever,
    EngagementRetriever,
    PersonalRetriever,
    MapRateLimitGuard,
  ],
  exports: [FeedRankingService],
})
export class SitesModule {}
