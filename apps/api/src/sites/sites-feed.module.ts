import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { FeatureFlagsModule } from '../feature-flags/feature-flags.module';
import { ModerationModule } from '../moderation/moderation.module';
import { ReportsUploadModule } from '../reports/reports-upload.module';
import { SiteCommentsCountModule } from './site-comments-count.module';
import { FeedRankingService } from './services/feed-ranking.service';
import { SitesFeedService } from './services/sites-feed.service';
import { SitesFeedCandidatesService } from './services/sites-feed-candidates.service';
import { SitesFeedEnrichmentService } from './services/sites-feed-enrichment.service';
import { SitesFeedQueryService } from './services/sites-feed-query.service';
import { SitesFeedCacheService } from './services/sites-feed-cache.service';
import { SitesFeedPreferencesService } from './services/sites-feed-preferences.service';
import { SitesFeedTrackingService } from './services/sites-feed-tracking.service';
import { SitesSavedListService } from './services/sites-saved-list.service';
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
import { FeedCacheRedisService } from './feed/feed-cache-redis.service';

@Module({
  imports: [ConfigModule, ReportsUploadModule, FeatureFlagsModule, ModerationModule, SiteCommentsCountModule],
  providers: [
    SitesFeedCacheService,
    SitesFeedPreferencesService,
    SitesFeedTrackingService,
    SitesFeedCandidatesService,
    SitesFeedEnrichmentService,
    SitesFeedQueryService,
    SitesFeedService,
    SitesSavedListService,
    FeedRankingService,
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
    FeedCacheRedisService,
  ],
  exports: [SitesFeedService, FeedRankingService, SitesFeedCacheService, SitesSavedListService],
})
export class SitesFeedModule {}
