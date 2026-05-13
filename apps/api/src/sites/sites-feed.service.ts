import { Injectable } from '@nestjs/common';
import { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { ObservabilityStore } from '../observability/observability.store';
import { ListSitesQueryDto } from './dto/list-sites-query.dto';
import { SubmitFeedFeedbackDto } from './dto/submit-feed-feedback.dto';
import { TrackFeedEventDto } from './dto/track-feed-event.dto';
import { FeedVariant } from './feed/feed-v2.types';
import { assertFeedGeoPairComplete } from './sites-feed-geo.util';
import { SitesFeedCacheService } from './sites-feed-cache.service';
import { SitesFeedPreferencesService } from './sites-feed-preferences.service';
import { SitesFeedQueryService } from './sites-feed-query.service';
import { SitesFeedTrackingService } from './sites-feed-tracking.service';
import type { SitesFeedListResult } from './sites-feed.types';

export type { SitesFeedListResult } from './sites-feed.types';

@Injectable()
export class SitesFeedService {
  private readonly feedCacheTtlMs = 15_000;

  constructor(
    private readonly feedQuery: SitesFeedQueryService,
    private readonly feedCache: SitesFeedCacheService,
    private readonly preferences: SitesFeedPreferencesService,
    private readonly tracking: SitesFeedTrackingService,
  ) {}

  async findAll(query: ListSitesQueryDto, user?: AuthenticatedUser): Promise<SitesFeedListResult> {
    const startedAt = Date.now();
    const cacheKey = this.feedCache.buildFeedCacheKey(query, user);
    const cached = this.feedCache.get(cacheKey);
    const nowMs = Date.now();
    if (cached && nowMs - cached.cachedAt <= this.feedCacheTtlMs) {
      ObservabilityStore.recordFeedRequest({
        durationMs: Date.now() - startedAt,
        candidatePoolSize: cached.value.data.length,
        cacheHit: true,
      });
      return cached.value;
    }
    assertFeedGeoPairComplete(query);

    try {
      return await this.feedQuery.computeFeedList(query, user, { startedAt, nowMs, cacheKey });
    } catch (error) {
      if (cached) {
        ObservabilityStore.recordFeedRequest({
          durationMs: Date.now() - startedAt,
          candidatePoolSize: cached.value.data.length,
          cacheHit: true,
        });
        return cached.value;
      }
      throw error;
    }
  }

  getFeedVariantForUser(userId: string | undefined): FeedVariant {
    return this.preferences.getFeedVariantForUser(userId);
  }

  trackFeedEvent(dto: TrackFeedEventDto, user: AuthenticatedUser) {
    return this.tracking.trackFeedEvent(dto, user);
  }

  submitFeedFeedback(siteId: string, dto: SubmitFeedFeedbackDto, user: AuthenticatedUser) {
    return this.tracking.submitFeedFeedback(siteId, dto, user);
  }

  invalidateFeedCache(reason: string, siteId?: string): void {
    this.feedCache.invalidate(reason, siteId);
  }
}
