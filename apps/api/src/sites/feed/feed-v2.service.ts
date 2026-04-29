import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { ObservabilityStore } from '../../observability/observability.store';
import { ListSitesQueryDto, SiteFeedMode, SiteFeedSort } from '../dto/list-sites-query.dto';
import { FeedCandidate, FeedVariant } from './feed-v2.types';
import { AssignmentService } from './experiments/assignment.service';
import { FeatureExtractor } from './features/feature-extractor';
import { UserStateRepository } from './features/user-state.repository';
import { reasonsFromFeatures } from './explain/reasons';
import { OnnxRanker } from './ranker/onnx-ranker';
import { DiversityRerank } from './rerank/diversity-rerank';
import { PersonalizationRerank } from './rerank/personalization-rerank';
import { PolicyRerank } from './rerank/policy-rerank';
import { CandidateGenerator } from './candidates/candidate-generator';

type FeedLikeRow = {
  id: string;
  rankingScore: number;
  rankingReasons: string[];
  rankingComponents?: Record<string, number> | undefined;
  createdAt: Date;
  distanceKm?: number;
  status: 'REPORTED' | 'VERIFIED' | 'CLEANUP_SCHEDULED' | 'IN_PROGRESS' | 'CLEANED' | 'DISPUTED';
  latestReportCategory: string | null;
  latestReportReporterId?: string | null;
  upvotesCount: number;
  commentsCount: number;
  savesCount: number;
  sharesCount: number;
  reportCount: number;
};

@Injectable()
export class FeedV2Service {
  private readonly logger = new Logger(FeedV2Service.name);
  constructor(
    private readonly config: ConfigService,
    private readonly assignmentService: AssignmentService,
    private readonly userStateRepo: UserStateRepository,
    private readonly featureExtractor: FeatureExtractor,
    private readonly onnxRanker: OnnxRanker,
    private readonly candidateGenerator: CandidateGenerator,
    private readonly personalizationRerank: PersonalizationRerank,
    private readonly diversityRerank: DiversityRerank,
    private readonly policyRerank: PolicyRerank,
  ) {}

  async resolveVariant(user?: AuthenticatedUser): Promise<FeedVariant> {
    if (this.config.get<string>('FEED_V2_ENABLED') !== 'true') return 'v1';
    if (!user?.userId) return 'v1';
    return this.assignmentService.assign(user.userId);
  }

  async rerankRows<T extends FeedLikeRow>(
    rows: T[],
    query: ListSitesQueryDto,
    user: AuthenticatedUser | undefined,
    variant: FeedVariant,
  ): Promise<T[]> {
    if (variant === 'v1') return rows;
    if (query.sort !== SiteFeedSort.HYBRID || query.mode === SiteFeedMode.LATEST) return rows;
    if (!user?.userId || rows.length === 0) return rows;

    const stageStartedAt = Date.now();
    try {
      const userState = await this.userStateRepo.getState(user.userId);
      const stageCandidates = await this.candidateGenerator.generate({
        userId: user.userId,
        ...(query.lat != null ? { lat: query.lat } : {}),
        ...(query.lng != null ? { lng: query.lng } : {}),
        radiusKm: query.radiusKm,
        limit: Math.min(180, Math.max(60, rows.length * 3)),
        ...(query.status ? { status: query.status } : {}),
      });
      const stageScoreBySiteId = new Map(
        stageCandidates.map((row) => [row.siteId, row.candidateStage.scoreHint]),
      );
      const candidates = rows.map((row): FeedCandidate => ({
      siteId: row.id,
      createdAt: row.createdAt,
      status: row.status,
      latestReportCategory: row.latestReportCategory,
      latestReportReporterId: row.latestReportReporterId ?? null,
      ...(row.distanceKm != null ? { distanceKm: row.distanceKm } : {}),
      rankingScore: row.rankingScore,
      reportCount: row.reportCount,
      upvotesCount: row.upvotesCount,
      commentsCount: row.commentsCount,
      savesCount: row.savesCount,
      sharesCount: row.sharesCount,
      rankingReasons: row.rankingReasons,
      ...(row.rankingComponents ? { rankingComponents: row.rankingComponents } : {}),
      }));
      const features = await this.featureExtractor.extract({ candidates, userState });
      const mlScores = await this.onnxRanker.score(features);

      const mixed = candidates.map((candidate, idx) => ({
      ...candidate,
      rankingScore:
        candidate.rankingScore * 0.45 +
        (mlScores[idx] ?? 0) * 0.55 +
        (stageScoreBySiteId.get(candidate.siteId) ?? 0) * 0.08,
      rankingReasons: reasonsFromFeatures(features[idx]),
      rankingComponents: query.explain
        ? {
            ...(candidate.rankingComponents ?? {}),
            ml: mlScores[idx] ?? 0,
            mix: 0.55,
          }
        : candidate.rankingComponents,
      }));
      const personalized = this.personalizationRerank.apply(mixed, userState);
      const diversity = this.diversityRerank.apply(personalized);
      const policy = this.policyRerank.apply(diversity);
      const byId = new Map(policy.map((row) => [row.siteId, row] as const));
      const out = rows
      .map((row) => {
        const ranked = byId.get(row.id);
        if (!ranked) return row;
        return {
          ...row,
          rankingScore: ranked.rankingScore,
          rankingReasons: ranked.rankingReasons,
          rankingComponents: ranked.rankingComponents,
        };
      })
      .sort((a, b) => b.rankingScore - a.rankingScore);

      ObservabilityStore.recordFeedV2Request(false);
      ObservabilityStore.recordFeedV2StageLatency('rerank', Date.now() - stageStartedAt);
      ObservabilityStore.setFeedV2ModelVersion(this.onnxRanker.modelVersion());
      if (variant === 'v2-shadow') {
        ObservabilityStore.recordFeedV2ShadowComparison({
          top10Overlap: this.topKOverlap(rows, out, 10),
          avgAbsDelta: this.avgAbsScoreDelta(rows, out),
        });
        return rows;
      }
      return out;
    } catch (error) {
      ObservabilityStore.recordFeedV2Request(true);
      this.logger.warn(
        `Feed V2 rerank fallback to v1 ordering: ${
          error instanceof Error ? error.message : String(error)
        }`,
      );
      return rows;
    }
  }

  private topKOverlap<T extends { id: string }>(before: T[], after: T[], k: number): number {
    const left = new Set(before.slice(0, k).map((row) => row.id));
    const right = new Set(after.slice(0, k).map((row) => row.id));
    let overlap = 0;
    for (const id of left) {
      if (right.has(id)) overlap += 1;
    }
    return k > 0 ? overlap / Math.min(k, Math.max(left.size, right.size, 1)) : 0;
  }

  private avgAbsScoreDelta<T extends { id: string; rankingScore: number }>(before: T[], after: T[]): number {
    const beforeById = new Map(before.map((row) => [row.id, row.rankingScore]));
    let total = 0;
    let count = 0;
    for (const row of after) {
      const prev = beforeById.get(row.id);
      if (prev == null) continue;
      total += Math.abs(row.rankingScore - prev);
      count += 1;
    }
    return count > 0 ? total / count : 0;
  }
}
