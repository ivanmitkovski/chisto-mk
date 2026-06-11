import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditService } from '../../audit/services/audit.service';
import { AuthenticatedUser } from '../../auth/types/authenticated-user.type';

const GAMIFICATION_CONFIG_KEY = 'admin_gamification_config';

export type GamificationConfig = {
  levelThresholds: number[];
  pointValues: Record<string, number>;
};

const DEFAULT_CONFIG: GamificationConfig = {
  levelThresholds: [0, 100, 250, 500, 1000, 2000],
  pointValues: {
    FIRST_REPORT: 10,
    REPORT_APPROVED: 25,
    EVENT_CHECK_IN: 15,
  },
};

@Injectable()
export class AdminGamificationService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit?: AuditService,
  ) {}

  async getConfig(): Promise<GamificationConfig> {
    const row = await this.prisma.systemConfig.findUnique({ where: { key: GAMIFICATION_CONFIG_KEY } });
    if (!row?.value) return DEFAULT_CONFIG;
    try {
      return { ...DEFAULT_CONFIG, ...(JSON.parse(row.value) as GamificationConfig) };
    } catch {
      return DEFAULT_CONFIG;
    }
  }

  async updateConfig(config: GamificationConfig, actor: AuthenticatedUser): Promise<GamificationConfig> {
    await this.prisma.systemConfig.upsert({
      where: { key: GAMIFICATION_CONFIG_KEY },
      create: { key: GAMIFICATION_CONFIG_KEY, value: JSON.stringify(config) },
      update: { value: JSON.stringify(config) },
    });
    await this.audit?.log({
      actorId: actor.userId,
      action: 'GAMIFICATION_CONFIG_UPDATED',
      resourceType: 'SystemConfig',
      resourceId: GAMIFICATION_CONFIG_KEY,
      metadata: config,
    });
    return config;
  }

  async listUserPoints(userId: string, page = 1, limit = 50) {
    const user = await this.prisma.user.findUnique({ where: { id: userId }, select: { id: true, pointsBalance: true } });
    if (!user) {
      throw new NotFoundException({ code: 'USER_NOT_FOUND', message: 'User not found' });
    }
    const skip = (page - 1) * limit;
    const [data, total] = await this.prisma.$transaction([
      this.prisma.pointTransaction.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.pointTransaction.count({ where: { userId } }),
    ]);
    return { userId, balance: user.pointsBalance, data, meta: { page, limit, total } };
  }

  async adjustPoints(
    userId: string,
    delta: number,
    reasonCode: string,
    actor: AuthenticatedUser,
    note?: string,
  ) {
    const user = await this.prisma.user.findUnique({ where: { id: userId }, select: { id: true, pointsBalance: true } });
    if (!user) {
      throw new NotFoundException({ code: 'USER_NOT_FOUND', message: 'User not found' });
    }
    const balanceAfter = user.pointsBalance + delta;
    const [tx] = await this.prisma.$transaction([
      this.prisma.pointTransaction.create({
        data: {
          userId,
          delta,
          balanceAfter,
          reasonCode,
          referenceType: 'admin_adjustment',
          referenceId: actor.userId,
          ...(note ? { metadata: { note } } : {}),
        },
      }),
      this.prisma.user.update({ where: { id: userId }, data: { pointsBalance: balanceAfter } }),
    ]);
    await this.audit?.log({
      actorId: actor.userId,
      action: 'POINTS_ADJUSTED',
      resourceType: 'User',
      resourceId: userId,
      metadata: { delta, balanceAfter, reasonCode, note: note ?? null },
    });
    return tx;
  }
}
