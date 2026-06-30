import { Injectable } from '@nestjs/common';
import { FeedCandidateWithStage } from '../feed-v2.types';
import { PrismaService } from '../../../prisma/prisma.service';
import type { CandidateRequestContext } from './candidate-request-context';
import { toStageCandidate } from './candidate-mapper';

@Injectable()
export class FreshnessRetriever {
  constructor(private readonly prisma: PrismaService) {}

  async retrieve(context: CandidateRequestContext): Promise<FeedCandidateWithStage[]> {
    const since = new Date(Date.now() - 72 * 60 * 60 * 1000);
    const rows = await this.prisma.site.findMany({
      where: {
        ...(context.status ? { status: context.status } : {}),
        createdAt: { gte: since },
      },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
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
    return rows.map((row) => toStageCandidate(row, 'freshness', 0.85));
  }
}
