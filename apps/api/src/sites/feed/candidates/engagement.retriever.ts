import { Injectable } from '@nestjs/common';
import { FeedCandidateWithStage } from '../feed-v2.types';
import { PrismaService } from '../../../prisma/prisma.service';
import type { CandidateRequestContext } from './candidate-request-context';
import { toStageCandidate } from './candidate-mapper';

@Injectable()
export class EngagementRetriever {
  constructor(private readonly prisma: PrismaService) {}

  async retrieve(context: CandidateRequestContext): Promise<FeedCandidateWithStage[]> {
    const rows = await this.prisma.site.findMany({
      where: {
        ...(context.status ? { status: context.status } : {}),
      },
      orderBy: [
        { sharesCount: 'desc' },
        { upvotesCount: 'desc' },
        { commentsCount: 'desc' },
        { createdAt: 'desc' },
        { id: 'desc' },
      ],
      take: Math.max(20, Math.min(200, context.limit ?? 120)),
      include: {
        reports: {
          orderBy: { createdAt: 'desc' },
          take: 1,
          select: { createdAt: true, category: true, reporterId: true },
        },
        _count: { select: { reports: true } },
      },
    });
    return rows.map((row) => toStageCandidate(row, 'engagement', 0.88));
  }
}
