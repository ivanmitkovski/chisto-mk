import { Injectable, NotFoundException } from '@nestjs/common';
import { Prisma, Role, UserStatus } from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditService } from '../../audit/services/audit.service';
import { ReportsUploadService } from '../../reports/services/reports-upload.service';
import {
  AdminUsersSortDir,
  AdminUsersSortField,
  ListAdminUsersQueryDto,
} from '../dto/list-admin-users-query.dto';

@Injectable()
export class AdminUsersQueryService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly reportsUploadService: ReportsUploadService,
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
      createdAt: string;
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
    if (query.createdAfter) {
      where.createdAt = { gte: new Date(query.createdAfter) };
    }

    const sortField = query.sort ?? AdminUsersSortField.CREATED;
    const sortDir = query.dir ?? AdminUsersSortDir.DESC;
    const orderBy = this.buildOrderBy(sortField, sortDir);

    const [rows, total] = await this.prisma.$transaction([
      this.prisma.user.findMany({
        where,
        orderBy,
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
          createdAt: true,
          pointsBalance: true,
        },
      }),
      this.prisma.user.count({ where }),
    ]);

    return {
      data: rows.map((u) => ({
        ...u,
        lastActiveAt: u.lastActiveAt?.toISOString() ?? null,
        createdAt: u.createdAt.toISOString(),
      })),
      meta: { page, limit, total },
    };
  }

  private buildOrderBy(
    sort: AdminUsersSortField,
    dir: AdminUsersSortDir,
  ): Prisma.UserOrderByWithRelationInput | Prisma.UserOrderByWithRelationInput[] {
    switch (sort) {
      case AdminUsersSortField.LAST_ACTIVE:
        return { lastActiveAt: dir };
      case AdminUsersSortField.NAME:
        return [{ lastName: dir }, { firstName: dir }];
      case AdminUsersSortField.EMAIL:
        return { email: dir };
      case AdminUsersSortField.POINTS:
        return { pointsBalance: dir };
      case AdminUsersSortField.CREATED:
      default:
        return { createdAt: dir };
    }
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
    organizerCertifiedAt: string | null;
    termsAcceptedAt: string | null;
    termsVersion: string | null;
    requiresTermsAcceptance: boolean;
    privacyAcceptedAt: string | null;
    lastActiveAt: string | null;
    createdAt: string;
    reportsCount: number;
    sessionsCount: number;
    avatarUrl: string | null;
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

    const avatarUrl = await this.reportsUploadService.signPrivateObjectKey(user.avatarObjectKey);

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
      organizerCertifiedAt: user.organizerCertifiedAt?.toISOString() ?? null,
      termsAcceptedAt: user.termsAcceptedAt?.toISOString() ?? null,
      termsVersion: user.termsVersion,
      requiresTermsAcceptance: !user.termsAcceptedAt,
      privacyAcceptedAt: user.privacyAcceptedAt?.toISOString() ?? null,
      lastActiveAt: user.lastActiveAt?.toISOString() ?? null,
      createdAt: user.createdAt.toISOString(),
      reportsCount: user._count.reports,
      sessionsCount,
      avatarUrl,
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
