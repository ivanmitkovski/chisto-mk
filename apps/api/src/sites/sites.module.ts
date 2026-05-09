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
import { MapSiteRepositoryService } from './map/map-site-repository.service';
import { MapObservabilityService } from './map/map-observability.service';
import { MapProjectionUpdaterService } from './map/map-projection-updater.service';
import { MapLifecycleCronService } from './map/map-lifecycle-cron.service';
import { MapMvtTilesService } from './map/map-mvt-tiles.service';
import { SitesSearchService } from './sites-search.service';

@Module({
  imports: [AuditModule, ReportsUploadModule, AdminEventsModule],
  controllers: [SitesController],
  providers: [
    SitesMapQueryService,
    MapCacheService,
    MapQueryValidatorService,
    MapResponseProjectorService,
    MapSiteRepositoryService,
    MapObservabilityService,
    MapProjectionUpdaterService,
    MapLifecycleCronService,
    MapMvtTilesService,
    SitesSearchService,
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
  exports: [SitesService, FeedRankingService],
})
export class SitesModule {}
