import { ConflictException, Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { PostUgcReportDto } from './dto/post-ugc-report.dto';
import { PostUserBlockDto } from './dto/post-user-block.dto';

@Injectable()
export class ModerationService {
  constructor(private readonly prisma: PrismaService) {}

  async submitReport(user: AuthenticatedUser, dto: PostUgcReportDto) {
    const details = dto.details?.trim() || null;
    const report = await this.prisma.ugcContentReport.create({
      data: {
        reporterId: user.userId,
        subjectType: dto.subjectType,
        subjectId: dto.subjectId,
        reason: dto.reason,
        details,
      },
      select: { id: true, status: true, createdAt: true },
    });
    await this.prisma.adminNotification.create({
      data: {
        title: 'UGC report',
        message: `${dto.subjectType} reported (${dto.reason})`,
        timeLabel: 'now',
        tone: 'success',
        category: 'reports',
        href: '/moderation/ugc',
        messageTemplateKey: 'ugc.report.new',
        messageTemplateParams: {
          subjectType: dto.subjectType,
          subjectId: dto.subjectId,
          reason: dto.reason,
        },
      },
    });
    return report;
  }

  async blockUser(user: AuthenticatedUser, dto: PostUserBlockDto) {
    if (dto.blockedUserId === user.userId) {
      throw new ConflictException('Cannot block yourself');
    }
    return this.prisma.userBlock.upsert({
      where: {
        blockerId_blockedUserId: {
          blockerId: user.userId,
          blockedUserId: dto.blockedUserId,
        },
      },
      create: {
        blockerId: user.userId,
        blockedUserId: dto.blockedUserId,
      },
      update: {},
      select: { id: true, blockedUserId: true, createdAt: true },
    });
  }

  async listBlocks(user: AuthenticatedUser) {
    return this.prisma.userBlock.findMany({
      where: { blockerId: user.userId },
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        blockedUserId: true,
        createdAt: true,
        blocked: {
          select: {
            id: true,
            firstName: true,
            lastName: true,
          },
        },
      },
    });
  }

  async unblock(user: AuthenticatedUser, blockedUserId: string) {
    await this.prisma.userBlock.deleteMany({
      where: { blockerId: user.userId, blockedUserId },
    });
    return { ok: true };
  }

  /** User ids the caller has blocked (for UGC list filtering). */
  async blockedUserIdsFor(blockerId: string): Promise<string[]> {
    const rows = await this.prisma.userBlock.findMany({
      where: { blockerId },
      select: { blockedUserId: true },
    });
    return rows.map((r) => r.blockedUserId);
  }
}
