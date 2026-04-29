import { Injectable } from '@nestjs/common';
import { FEATURE_VECTOR_VERSION, FeatureVectorV1 } from './feature-vector.types';
import { FeedCandidate, FeedUserState } from '../feed-v2.types';
import { SiteFeatureRepository } from './site-feature.repository';

@Injectable()
export class FeatureExtractor {
  constructor(private readonly siteFeatureRepo: SiteFeatureRepository) {}

  async extract(input: { candidates: FeedCandidate[]; userState: FeedUserState }): Promise<FeatureVectorV1[]> {
    const snapshotBySiteId = await this.siteFeatureRepo.findMany(input.candidates.map((c) => c.siteId));
    const now = Date.now();
    return input.candidates.map((candidate) => {
      const fromSnapshot = snapshotBySiteId.get(candidate.siteId);
      const freshnessHours =
        fromSnapshot?.freshnessHours ??
        Math.max(0, (now - candidate.createdAt.getTime()) / (60 * 60 * 1000));
      return {
        version: FEATURE_VECTOR_VERSION,
        siteId: candidate.siteId,
        engagementVelocity24h: fromSnapshot?.velocity24h ?? 0,
        engagementIntensity:
          (candidate.upvotesCount + candidate.commentsCount * 1.6 + candidate.sharesCount * 1.8 + candidate.savesCount * 1.2) /
          Math.max(1, candidate.reportCount),
        freshnessHours,
        distanceKm: candidate.distanceKm ?? 999,
        statusTrust: candidate.status === 'VERIFIED' ? 1 : candidate.status === 'DISPUTED' ? 0.35 : 0.75,
        severityIndex: fromSnapshot?.severityIndex ?? 0,
        discussionRatio: fromSnapshot?.discussionRatio ?? 0,
        intentRatio: fromSnapshot?.intentRatio ?? 0,
        reportCount: candidate.reportCount,
        wasSeenRecently: input.userState.seenSiteIds.has(candidate.siteId) ? 1 : 0,
        followsReporter:
          candidate.latestReportReporterId && input.userState.followReporterIds.has(candidate.latestReportReporterId)
            ? 1
            : 0,
      };
    });
  }
}
