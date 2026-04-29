import { Prisma } from '../../../prisma-client';
import { FeedCandidateWithStage } from '../feed-v2.types';

export type RetrieverSiteRow = Prisma.SiteGetPayload<{
  include: {
    reports: {
      orderBy: { createdAt: 'desc' };
      take: 1;
      select: { createdAt: true; category: true; reporterId: true };
    };
    _count: { select: { reports: true } };
  };
}>;

export function toStageCandidate(
  row: RetrieverSiteRow,
  stage: FeedCandidateWithStage['candidateStage']['retriever'],
  scoreHint: number,
): FeedCandidateWithStage {
  const latestReport = row.reports[0];
  return {
    siteId: row.id,
    createdAt: latestReport?.createdAt ?? row.createdAt,
    status: row.status,
    latestReportCategory: latestReport?.category ?? null,
    latestReportReporterId: latestReport?.reporterId ?? null,
    rankingScore: 0,
    reportCount: row._count.reports,
    upvotesCount: row.upvotesCount,
    commentsCount: row.commentsCount,
    savesCount: row.savesCount,
    sharesCount: row.sharesCount,
    rankingReasons: [stage],
    candidateStage: { retriever: stage, scoreHint },
  };
}
