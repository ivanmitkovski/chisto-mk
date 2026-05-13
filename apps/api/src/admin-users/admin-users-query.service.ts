import { Injectable, NotFoundException } from '@nestjs/common';
import { Prisma, Role, UserStatus } from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import { AuditService } from '../audit/audit.service';
import { ListAdminUsersQueryDto } from './dto/list-admin-users-query.dto';

@Injectable()
export class AdminUsersQueryService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
  ) {}

  async list(query: ListAdminUsersQueryDto): Promise<{
    data: Array<{
      id: string;
      firstName: string;
      lastName: string;
      email: string;
      phoneNumber: string;
      role: Role;
      status: UserStatus;
      lastActiveAt: string | null;
      pointsBalance: number;
    }>;
    meta: { page: number; limit: number; total: number };
  }> {
    const page = query.page ?? 1;
    const limit = query.limit ?? 20;
    const skip = (page - 1) * limit;

    const where: Prisma.UserWhereInput = {};
    if (query.status) {
      where.status = query.status;
    }
    if (query.role) {
      where.role = query.role;
    }
    if (query.search?.trim()) {
      const q = query.search.trim();
      where.OR = [
        { email: { contains: q, mode: 'insensitive' } },
        { phoneNumber: { contains: q } },
        { firstName: { contains: q, mode: 'insensitive' } },
        { lastName: { contains: q, mode: 'insensitive' } },
      ];
    }
    if (query.lastActiveBefore) {
      where.lastActiveAt = where.lastActiveAt ?? {};
      (where.lastActiveAt as Record<string, unknown>).lt = new Date(query.lastActiveBefore);
    }
    if (query.lastActiveAfter) {
      where.lastActiveAt = where.lastActiveAt ?? {};
      (where.lastActiveAt as Record<string, unknown>).gte = new Date(query.lastActiveAfter);
    }

    const [rows, total] = await this.prisma.$transaction([
      this.prisma.user.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
        select: {
          id: true,
          firstName: true,
          lastName: true,
          email: true,
          phoneNumber: true,
          role: true,
          status: true,
          lastActiveAt: true,
          pointsBalance: true,
        },
      }),
      this.prisma.user.count({ where }),
    ]);

    return {
      data: rows.map((u) => ({
        ...u,
        lastActiveAt: u.lastActiveAt?.toISOString() ?? null,
      })),
      meta: { page, limit, total },
    };
  }

  async findOne(id: string): Promise<{
    id: string;
    firstName: string;
    lastName: string;
    email: string;
    phoneNumber: string;
    role: Role;
    status: UserStatus;
    isPhoneVerified: boolean;
    pointsBalance: number;
    totalPointsEarned: number;
    totalPointsSpent: number;
    lastActiveAt: string | null;
    createdAt: string;
    reportsCount: number;
    sessionsCount: number;
  }> {
    const user = await this.prisma.user.findUnique({
      where: { id },
      include: {
        _count: {
          select: { reports: true },
        },
      },
    });

    if (!user) {
      throw new NotFoundException({
        code: 'USER_NOT_FOUND',
        message: 'User not found',
      });
    }

    const now = new Date();
    const sessionsCount = await this.prisma.userSession.count({
      where: {
        userId: id,
        revokedAt: null,
        expiresAt: { gt: now },
      },
    });

    return {
      id: user.id,
      firstName: user.firstName,
      lastName: user.lastName,
      email: user.email,
      phoneNumber: user.phoneNumber,
      role: user.role,
      status: user.status,
      isPhoneVerified: user.isPhoneVerified,
      pointsBalance: user.pointsBalance,
      totalPointsEarned: user.totalPointsEarned,
      totalPointsSpent: user.totalPointsSpent,
      lastActiveAt: user.lastActiveAt?.toISOString() ?? null,
      createdAt: user.createdAt.toISOString(),
      reportsCount: user._count.reports,
      sessionsCount,
    };
  }

  async getAudit(userId: string, page: number, limit: number) {
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
    return this.audit.listForUser(userId, { page, limit });
  }

  async getSessions(userId: string) {
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
    const sessions = await this.prisma.userSession.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      select: {
        id: true,
        createdAt: true,
        deviceInfo: true,
        ipAddress: true,
        expiresAt: true,
        revokedAt: true,
      },
    });
    return sessions.map((s) => ({
      id: s.id,
      createdAt: s.createdAt.toISOString(),
      deviceInfo: s.deviceInfo,
      ipAddress: s.ipAddress,
      expiresAt: s.expiresAt.toISOString(),
      revokedAt: s.revokedAt?.toISOString() ?? null,
    }));
  }
}
