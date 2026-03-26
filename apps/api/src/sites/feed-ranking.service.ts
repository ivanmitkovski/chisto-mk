import { Injectable } from '@nestjs/common';

export type RankingInput = {
  siteId: string;
  createdAt: Date;
  upvotesCount: number;
  commentsCount: number;
  savesCount: number;
  sharesCount: number;
  status: string;
  distanceKm?: number;
  radiusKm?: number;
  reportCount?: number;
  sessionCategoryAffinity?: number;
  sessionGeoAffinity?: number;
  sessionStatusAffinity?: number;
  engagementVelocity?: number;
  duplicateContentPenalty?: number;
  policyEligibility?: number;
};

export type RankingExplainability = {
  score: number;
  components: {
    recency: number;
    engagement: number;
    distance: number;
    trust: number;
    antiGamingPenalty: number;
    explorationBoost: number;
    sessionBoost: number;
    jitter: number;
  };
  reasonCodes: string[];
};

@Injectable()
export class FeedRankingService {
  // Freshness decays smoothly; balanced to keep quality posts visible for ~1-2 days.
  private static readonly RECENCY_HALF_LIFE_HOURS = 26;
  // Balanced weight profile: freshness + engagement quality + local relevance + trust.
  private static readonly WEIGHT_RECENCY = 0.34;
  private static readonly WEIGHT_ENGAGEMENT = 0.38;
  private static readonly WEIGHT_DISTANCE = 0.2;
  private static readonly WEIGHT_TRUST = 0.08;
  // Anti-gaming and saturation controls.
  private static readonly MAX_EFFECTIVE_UPVOTES = 80;
  private static readonly MAX_EFFECTIVE_COMMENTS = 55;
  private static readonly MAX_EFFECTIVE_SAVES = 45;
  private static readonly MAX_EFFECTIVE_SHARES = 40;
  private static readonly BURSTY_LOW_QUALITY_PENALTY = 0.1;
  // Medium exploration: small deterministic uplift for promising underexposed posts.
  private static readonly EXPLORATION_BOOST_MAX = 0.14;
  private static readonly SESSION_BOOST_MAX = 0.12;
  private static readonly FEATURE_FLAG_SESSION_AFFINITY =
    process.env.FEED_RANKER_SESSION_AFFINITY !== 'false';
  private static readonly FEATURE_FLAG_EXPLORATION =
    process.env.FEED_RANKER_EXPLORATION !== 'false';
  private static readonly FEATURE_FLAG_ANTI_GAMING =
    process.env.FEED_RANKER_ANTI_GAMING !== 'false';

  private static readonly STATUS_MULTIPLIER: Record<string, number> = {
    VERIFIED: 1.06,
    CLEANUP_SCHEDULED: 1.045,
    IN_PROGRESS: 1.03,
    REPORTED: 1,
    CLEANED: 0.95,
    DISPUTED: 0.86,
  };

  score(input: RankingInput, now = new Date()): number {
    return this.scoreDetailed(input, now).score;
  }

  scoreDetailed(input: RankingInput, now = new Date()): RankingExplainability {
    const recency = this.computeRecencyScore(input.createdAt, now);
    const engagement = this.computeEngagementQualityScore(input);
    const distance = this.computeDistanceRelevanceScore(input.distanceKm, input.radiusKm);
    const trust = this.computeTrustScore(input.status);
    const antiGamingPenalty = FeedRankingService.FEATURE_FLAG_ANTI_GAMING
      ? this.computeAntiGamingPenalty(input)
      : 0;
    const exploration = FeedRankingService.FEATURE_FLAG_EXPLORATION
      ? this.computeExplorationBoost(input, recency)
      : 0;
    const sessionBoost = FeedRankingService.FEATURE_FLAG_SESSION_AFFINITY
      ? this.computeSessionBoost(input)
      : 0;
    const jitter = this.deterministicJitter(input.siteId, now);

    const weightedBase =
      recency * FeedRankingService.WEIGHT_RECENCY +
      engagement * FeedRankingService.WEIGHT_ENGAGEMENT +
      distance * FeedRankingService.WEIGHT_DISTANCE +
      trust * FeedRankingService.WEIGHT_TRUST;
    const velocityDampening = Math.max(
      0,
      Math.min(0.18, (input.engagementVelocity ?? 0) * 0.18),
    );
    const duplicateDampening = Math.max(0, Math.min(0.15, input.duplicateContentPenalty ?? 0));
    const policyMultiplier = Math.max(0.2, Math.min(1, input.policyEligibility ?? 1));
    const score =
      (weightedBase * (1 - antiGamingPenalty - velocityDampening - duplicateDampening) +
        exploration +
        sessionBoost +
        jitter) *
      policyMultiplier;
    return {
      score,
      components: {
        recency,
        engagement,
        distance,
        trust,
        antiGamingPenalty,
        explorationBoost: exploration,
        sessionBoost,
        jitter,
      },
      reasonCodes: this.buildReasonCodes(input, {
        recency,
        engagement,
        distance,
        trust,
        antiGamingPenalty,
        exploration,
        sessionBoost,
      }),
    };
  }

  private computeRecencyScore(createdAt: Date, now: Date): number {
    const ageHours = Math.max(0, (now.getTime() - createdAt.getTime()) / (1000 * 60 * 60));
    const base = Math.exp(-Math.log(2) * (ageHours / FeedRankingService.RECENCY_HALF_LIFE_HOURS));
    const freshnessKick = ageHours <= 12 ? 0.06 : 0;
    return Math.min(1.25, base + freshnessKick);
  }

  private computeEngagementQualityScore(input: RankingInput): number {
    const upvotes = Math.min(FeedRankingService.MAX_EFFECTIVE_UPVOTES, Math.max(0, input.upvotesCount));
    const comments = Math.min(
      FeedRankingService.MAX_EFFECTIVE_COMMENTS,
      Math.max(0, input.commentsCount),
    );
    const saves = Math.min(FeedRankingService.MAX_EFFECTIVE_SAVES, Math.max(0, input.savesCount));
    const shares = Math.min(
      FeedRankingService.MAX_EFFECTIVE_SHARES,
      Math.max(0, input.sharesCount),
    );

    const weightedSignals = upvotes * 1 + comments * 1.8 + saves * 1.65 + shares * 2.25;
    const base = Math.log1p(weightedSignals) / Math.log1p(300);
    const discussionHealth = Math.min(1, comments / (upvotes + 1));
    const intentHealth = Math.min(1, (saves + shares) / (upvotes + comments + 1));
    return Math.min(1.4, base * 0.72 + discussionHealth * 0.18 + intentHealth * 0.1);
  }

  private computeDistanceRelevanceScore(distanceKm?: number, radiusKm?: number): number {
    if (distanceKm == null || radiusKm == null || radiusKm <= 0) return 0.55;
    const normalized = Math.max(0, Math.min(1, distanceKm / radiusKm));
    // Smooth curve keeps nearby content advantaged without hard discontinuities.
    return Math.max(0, 1 - Math.pow(normalized, 1.4));
  }

  private computeTrustScore(status: string): number {
    return FeedRankingService.STATUS_MULTIPLIER[status] ?? 1;
  }

  private computeAntiGamingPenalty(input: RankingInput): number {
    const upvotes = Math.max(0, input.upvotesCount);
    const comments = Math.max(0, input.commentsCount);
    const saves = Math.max(0, input.savesCount);
    const shares = Math.max(0, input.sharesCount);
    const lowQualityVelocity = upvotes > 25 && comments <= 1 && saves + shares <= 1;
    return lowQualityVelocity ? FeedRankingService.BURSTY_LOW_QUALITY_PENALTY : 0;
  }

  private computeExplorationBoost(input: RankingInput, recencyScore: number): number {
    const exposure = Math.max(0, input.upvotesCount + input.commentsCount + input.savesCount + input.sharesCount);
    const underExposed = exposure < 8 ? 1 : 0;
    const reportDensity = Math.min(1, (input.reportCount ?? 0) / 4);
    const qualityGate = input.commentsCount + input.savesCount + input.sharesCount > 0 ? 1 : 0;
    const potential = underExposed * qualityGate * (0.65 * recencyScore + 0.35 * reportDensity);
    return Math.min(FeedRankingService.EXPLORATION_BOOST_MAX, potential * FeedRankingService.EXPLORATION_BOOST_MAX);
  }

  private computeSessionBoost(input: RankingInput): number {
    const category = Math.max(0, Math.min(1, input.sessionCategoryAffinity ?? 0));
    const geo = Math.max(0, Math.min(1, input.sessionGeoAffinity ?? 0));
    const status = Math.max(0, Math.min(1, input.sessionStatusAffinity ?? 0));
    const blend = category * 0.45 + geo * 0.35 + status * 0.2;
    return Math.min(FeedRankingService.SESSION_BOOST_MAX, blend * FeedRankingService.SESSION_BOOST_MAX);
  }

  private buildReasonCodes(
    input: RankingInput,
    features: {
      recency: number;
      engagement: number;
      distance: number;
      trust: number;
      antiGamingPenalty: number;
      exploration: number;
      sessionBoost: number;
    },
  ): string[] {
    const reasons: string[] = [];
    if (features.recency > 0.9) reasons.push('fresh_report');
    if (features.engagement > 0.55) reasons.push('strong_community_engagement');
    if (input.distanceKm != null && features.distance > 0.65) reasons.push('near_your_area');
    if (features.trust > 1.02) reasons.push('verified_or_active_status');
    if (features.exploration > 0.01) reasons.push('under_exposed_quality_boost');
    if (features.sessionBoost > 0.01) reasons.push('matches_your_recent_activity');
    if (features.antiGamingPenalty > 0) reasons.push('integrity_dampened');
    if ((input.engagementVelocity ?? 0) > 0.6) reasons.push('velocity_dampened');
    if ((input.duplicateContentPenalty ?? 0) > 0.05) reasons.push('duplicate_content_dampened');
    if ((input.policyEligibility ?? 1) < 1) reasons.push('policy_demoted');
    if (reasons.length === 0) reasons.push('balanced_feed_rank');
    return reasons;
  }

  private deterministicJitter(siteId: string, now: Date): number {
    const bucket = `${siteId}:${Math.floor(now.getTime() / (1000 * 60 * 60))}`;
    let hash = 0;
    for (let i = 0; i < bucket.length; i++) {
      hash = (hash * 31 + bucket.charCodeAt(i)) | 0;
    }
    return ((Math.abs(hash) % 1000) / 1000 - 0.5) * 0.02;
  }
}
