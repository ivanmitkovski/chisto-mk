import { Injectable } from '@nestjs/common';
import { FeedCandidateWithStage } from '../feed-v2.types';
import { PrismaService } from '../../../prisma/prisma.service';
import { CandidateRequestContext } from './candidate-generator';
import { UserStateRepository } from '../features/user-state.repository';
import { toStageCandidate } from './candidate-mapper';

@Injectable()
export class PersonalRetriever {
  constructor(
    private readonly prisma: PrismaService,
    private readonly userStateRepo: UserStateRepository,
  ) {}

  async retrieve(context: CandidateRequestContext): Promise<FeedCandidateWithStage[]> {
    if (!context.userId) return [];
    const userState = await this.userStateRepo.getState(context.userId);
    if (userState.followReporterIds.size === 0) return [];
    const rows = await this.prisma.site.findMany({
      where: {
        ...(context.status ? { status: context.status } : {}),
        reports: {
          some: {
            reporterId: { in: [...userState.followReporterIds] },
          },
        },
      },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take: Math.max(20, Math.min(120, context.limit ?? 80)),
      include: {
        reports: {
          orderBy: { createdAt: 'desc' },
          take: 1,
          select: { createdAt: true, category: true, reporterId: true },
        },
        _count: { select: { reports: true } },
      },
    });
    return rows.map((row) => toStageCandidate(row, 'personal', 0.95));
  }
}
