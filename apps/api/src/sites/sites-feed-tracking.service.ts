import { Injectable } from '@nestjs/common';
import { Prisma } from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import { AuditService } from '../audit/audit.service';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { ObservabilityStore } from '../observability/observability.store';
import { SubmitFeedFeedbackDto } from './dto/submit-feed-feedback.dto';
import { TrackFeedEventDto } from './dto/track-feed-event.dto';
import { SiteEngagementService } from './site-engagement.service';
import { UserStateRepository } from './feed/features/user-state.repository';
import { SitesFeedCacheService } from './sites-feed-cache.service';
import { SitesFeedPreferencesService } from './sites-feed-preferences.service';

@Injectable()
export class SitesFeedTrackingService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly siteEngagement: SiteEngagementService,
    private readonly userStateRepo: UserStateRepository,
    private readonly preferences: SitesFeedPreferencesService,
    private readonly feedCache: SitesFeedCacheService,
  ) {}

  async trackFeedEvent(dto: TrackFeedEventDto, user: AuthenticatedUser) {
    await this.siteEngagement.ensureSiteExists(dto.siteId);
    const metadata = {
      sessionId: dto.sessionId ?? null,
      ...(dto.metadata ? { metadata: dto.metadata } : {}),
    } as Prisma.InputJsonValue;
    void this.audit.log({
      actorId: user.userId,
      action: `FEED_EVENT_${dto.eventType.toUpperCase()}`,
      resourceType: 'Feed',
      resourceId: dto.siteId,
      metadata,
    });
    if (dto.eventType === 'impression') {
      this.preferences.recordImpression(user.userId, dto.siteId);
      await this.prisma.$executeRaw`
        INSERT INTO "FeedImpression" ("id","createdAt","userId","siteId","variant","position","dwellMs","engaged")
        VALUES (${`fi_${Date.now()}_${Math.random().toString(36).slice(2, 10)}`}, NOW(), ${user.userId}, ${dto.siteId}, ${this.preferences.getFeedVariantForUser(user.userId)}, NULL, NULL, false)
      `;
      await this.userStateRepo.cacheSeen(user.userId, dto.siteId, Date.now());
    }
    if (
      dto.eventType === 'save' ||
      dto.eventType === 'share' ||
      dto.eventType === 'comment_open' ||
      dto.eventType === 'detail_open' ||
      dto.eventType === 'skip' ||
      dto.eventType === 'bounce'
    ) {
      const profilePatch = JSON.stringify({
        signalCount: 1,
        latestEventType: dto.eventType,
        lastSiteId: dto.siteId,
        at: new Date().toISOString(),
      });
      await this.prisma.$executeRaw`
        INSERT INTO "UserFeedState" ("userId","engagementProfile","updatedAt","lastFeedAt")
        VALUES (${user.userId}, ${profilePatch}::jsonb, NOW(), NOW())
        ON CONFLICT ("userId")
        DO UPDATE SET
          "engagementProfile" = COALESCE("UserFeedState"."engagementProfile", '{}'::jsonb) || ${profilePatch}::jsonb,
          "updatedAt" = NOW(),
          "lastFeedAt" = NOW()
      `;
    }
    return { ok: true };
  }

  async submitFeedFeedback(siteId: string, dto: SubmitFeedFeedbackDto, user: AuthenticatedUser) {
    await this.siteEngagement.ensureSiteExists(siteId);
    const metadata = {
      sessionId: dto.sessionId ?? null,
      ...(dto.metadata ? { metadata: dto.metadata } : {}),
    } as Prisma.InputJsonValue;
    void this.audit.log({
      actorId: user.userId,
      action: `FEED_FEEDBACK_${dto.feedbackType.toUpperCase()}`,
      resourceType: 'Site',
      resourceId: siteId,
      metadata,
    });
    this.preferences.applyFeedFeedbackPreference(user.userId, siteId, dto.feedbackType);
    ObservabilityStore.recordFeedFeedback(dto.feedbackType);
    this.feedCache.invalidate('feed_feedback', siteId);
    return { ok: true, siteId, feedbackType: dto.feedbackType };
  }
}
