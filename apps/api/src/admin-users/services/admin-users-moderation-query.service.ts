import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class AdminUsersModerationQueryService {
  constructor(private readonly prisma: PrismaService) {}

  private async assertUserExists(userId: string): Promise<void> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true },
    });
    if (!user) {
      throw new NotFoundException({
        code: 'USER_NOT_FOUND',
        message: 'User not found',
      });
    }
  }

  async getSafetySummary(userId: string): Promise<{
    ugcReportsAsSubjectCount: number;
    recentUgcReports: Array<{
      id: string;
      status: string;
      reason: string;
      createdAt: string;
    }>;
    reportsFiledCount: number;
    blocksGivenCount: number;
    blocksReceivedCount: number;
  }> {
    await this.assertUserExists(userId);

    const [
      ugcReportsAsSubjectCount,
      recentUgcReports,
      reportsFiledCount,
      blocksGivenCount,
      blocksReceivedCount,
    ] = await Promise.all([
      this.prisma.ugcContentReport.count({
        where: { subjectType: 'user', subjectId: userId },
      }),
      this.prisma.ugcContentReport.findMany({
        where: { subjectType: 'user', subjectId: userId },
        orderBy: { createdAt: 'desc' },
        take: 5,
        select: { id: true, status: true, reason: true, createdAt: true },
      }),
      this.prisma.report.count({ where: { reporterId: userId } }),
      this.prisma.userBlock.count({ where: { blockerId: userId } }),
      this.prisma.userBlock.count({ where: { blockedUserId: userId } }),
    ]);

    return {
      ugcReportsAsSubjectCount,
      recentUgcReports: recentUgcReports.map((row) => ({
        id: row.id,
        status: row.status,
        reason: row.reason,
        createdAt: row.createdAt.toISOString(),
      })),
      reportsFiledCount,
      blocksGivenCount,
      blocksReceivedCount,
    };
  }

  async getModerationNotes(userId: string, page: number, limit: number) {
    await this.assertUserExists(userId);

    const skip = (page - 1) * limit;
    const [rows, total] = await this.prisma.$transaction([
      this.prisma.userModerationNote.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
        select: {
          id: true,
          body: true,
          createdAt: true,
          author: { select: { email: true, firstName: true, lastName: true } },
        },
      }),
      this.prisma.userModerationNote.count({ where: { userId } }),
    ]);

    return {
      data: rows.map((row) => ({
        id: row.id,
        body: row.body,
        createdAt: row.createdAt.toISOString(),
        authorEmail: row.author.email,
        authorName: `${row.author.firstName} ${row.author.lastName}`.trim(),
      })),
      meta: { page, limit, total },
    };
  }

  async getStatusHistory(userId: string, page: number, limit: number) {
    await this.assertUserExists(userId);

    const skip = (page - 1) * limit;
    const [rows, total] = await this.prisma.$transaction([
      this.prisma.userStatusAction.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
        select: {
          id: true,
          fromStatus: true,
          toStatus: true,
          reasonCode: true,
          note: true,
          createdAt: true,
          actor: { select: { email: true } },
        },
      }),
      this.prisma.userStatusAction.count({ where: { userId } }),
    ]);

    return {
      data: rows.map((row) => ({
        id: row.id,
        fromStatus: row.fromStatus,
        toStatus: row.toStatus,
        reasonCode: row.reasonCode,
        note: row.note,
        createdAt: row.createdAt.toISOString(),
        actorEmail: row.actor.email,
      })),
      meta: { page, limit, total },
    };
  }
}
