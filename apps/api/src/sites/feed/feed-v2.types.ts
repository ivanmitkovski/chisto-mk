import { SiteStatus } from '../../prisma-client';

export type FeedVariant = 'v1' | 'v2' | 'v2-shadow';

export type FeedCandidate = {
  siteId: string;
  createdAt: Date;
  status: SiteStatus;
  latestReportCategory: string | null;
  latestReportReporterId: string | null;
  distanceKm?: number;
  rankingScore: number;
  reportCount: number;
  upvotesCount: number;
  commentsCount: number;
  savesCount: number;
  sharesCount: number;
  rankingReasons: string[];
  rankingComponents?: Record<string, number> | undefined;
};

export type FeedCandidateStage = {
  retriever: 'geo' | 'freshness' | 'engagement' | 'personal';
  scoreHint: number;
};

export type FeedCandidateWithStage = FeedCandidate & {
  candidateStage: FeedCandidateStage;
};

export type FeedUserState = {
  hiddenSiteIds: Set<string>;
  mutedCategoryIds: Set<string>;
  followReporterIds: Set<string>;
  seenSiteIds: Map<string, number>;
};

export type FeedVariantResult<T> = {
  variant: FeedVariant;
  data: T[];
};
