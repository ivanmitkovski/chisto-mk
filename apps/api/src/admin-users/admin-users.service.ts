import { ConflictException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import { UserEventsService } from '../admin-events/user-events.service';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { AuditService } from '../audit/audit.service';
import { BulkAdminUsersDto } from './dto/bulk-admin-users.dto';
import { ListAdminUsersQueryDto } from './dto/list-admin-users-query.dto';
import { PatchAdminUserDto } from './dto/patch-admin-user.dto';
import { Role, UserStatus } from '../prisma-client';

@Injectable()
export class AdminUsersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly userEventsService: UserEventsService,
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

  async patch(
    id: string,
    dto: PatchAdminUserDto,
    actor: AuthenticatedUser,
  ): Promise<{ id: string; role: Role; status: UserStatus }> {
    if (actor.userId === id && dto.role != null && dto.role !== actor.role) {
      throw new ForbiddenException({
        code: 'CANNOT_CHANGE_OWN_ROLE',
        message: 'You cannot change your own role',
      });
    }

    const target = await this.prisma.user.findUnique({
      where: { id },
      select: { id: true, role: true, status: true, firstName: true, lastName: true, phoneNumber: true },
    });
    if (!target) {
      throw new NotFoundException({
        code: 'USER_NOT_FOUND',
        message: 'User not found',
      });
    }

    if (target.role === Role.SUPER_ADMIN && actor.role !== Role.SUPER_ADMIN) {
      throw new ForbiddenException({
        code: 'FORBIDDEN',
        message: 'Only a super admin can modify this account',
      });
    }

    if (dto.role === Role.SUPER_ADMIN && actor.role !== Role.SUPER_ADMIN) {
      throw new ForbiddenException({
        code: 'FORBIDDEN',
        message: 'Only a super admin can assign this role',
      });
    }

    const phoneValue = dto.phoneNumber != null ? dto.phoneNumber.trim() : null;
    if (phoneValue !== null && phoneValue !== '') {
      const existing = await this.prisma.user.findFirst({
        where: { phoneNumber: phoneValue, id: { not: id } },
      });
      if (existing) {
        throw new ConflictException({
          code: 'PHONE_NUMBER_IN_USE',
          message: 'Another user already has this phone number',
        });
      }
    }

    const data: Prisma.UserUpdateInput = {};
    if (dto.firstName != null) {
      data.firstName = dto.firstName.trim();
    }
    if (dto.lastName != null) {
      data.lastName = dto.lastName.trim();
    }
    if (phoneValue !== null && phoneValue !== '') {
      data.phoneNumber = phoneValue;
    }
    if (dto.status != null) {
      data.status = dto.status;
    }
    if (dto.role != null) {
      data.role = dto.role;
    }

    if (Object.keys(data).length === 0) {
      const u = await this.prisma.user.findUniqueOrThrow({
        where: { id },
        select: { id: true, firstName: true, lastName: true, phoneNumber: true, role: true, status: true },
      });
      return u;
    }

    const updated = await this.prisma.user.update({
      where: { id },
      data,
      select: { id: true, firstName: true, lastName: true, phoneNumber: true, role: true, status: true },
    });

    const changes: Record<string, { from: unknown; to: unknown }> = {};
    if (dto.firstName != null) {
      changes.firstName = { from: target.firstName, to: updated.firstName };
    }
    if (dto.lastName != null) {
      changes.lastName = { from: target.lastName, to: updated.lastName };
    }
    if (dto.phoneNumber != null) {
      changes.phoneNumber = { from: target.phoneNumber, to: updated.phoneNumber };
    }
    if (dto.status != null) {
      changes.status = { from: target.status, to: dto.status };
    }
    if (dto.role != null) {
      changes.role = { from: target.role, to: dto.role };
    }

    await this.audit.log({
      actorId: actor.userId,
      action: 'USER_UPDATED',
      resourceType: 'User',
      resourceId: id,
      metadata: { before: target, after: updated, changes } as Prisma.InputJsonValue,
    });

    this.userEventsService.emitUserUpdated(id);
    return updated;
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

  async bulk(dto: BulkAdminUsersDto, actor: AuthenticatedUser) {
    if (dto.action === 'changeRole' && dto.role == null) {
      throw new ConflictException({
        code: 'ROLE_REQUIRED',
        message: 'role is required when action is changeRole',
      });
    }
    const statusUpdate =
      dto.action === 'suspend'
        ? UserStatus.SUSPENDED
        : dto.action === 'activate'
          ? UserStatus.ACTIVE
          : undefined;

    const targets = await this.prisma.user.findMany({
      where: { id: { in: dto.userIds } },
      select: { id: true, role: true },
    });

    for (const t of targets) {
      if (t.role === Role.SUPER_ADMIN && actor.role !== Role.SUPER_ADMIN) continue;
      if (actor.userId === t.id && dto.action === 'changeRole' && dto.role !== actor.role) continue;
    }

    const data: Prisma.UserUpdateInput = {};
    if (statusUpdate != null) {
      data.status = statusUpdate;
    }
    if (dto.action === 'changeRole' && dto.role != null) {
      if (dto.role === Role.SUPER_ADMIN && actor.role !== Role.SUPER_ADMIN) {
        throw new ForbiddenException({
          code: 'FORBIDDEN',
          message: 'Only a super admin can assign this role',
        });
      }
      data.role = dto.role;
    }

    const toUpdate = dto.userIds.filter((id) => {
      const t = targets.find((x) => x.id === id);
      if (!t) return false;
      if (t.role === Role.SUPER_ADMIN && actor.role !== Role.SUPER_ADMIN) return false;
      if (actor.userId === id && dto.action === 'changeRole' && dto.role !== actor.role) return false;
      return true;
    });

    await this.prisma.user.updateMany({
      where: { id: { in: toUpdate } },
      data,
    });

    await this.audit.log({
      actorId: actor.userId,
      action: 'USERS_BULK_UPDATED',
      resourceType: 'User',
      metadata: {
        userIds: toUpdate,
        action: dto.action,
        role: dto.role,
        skippedCount: dto.userIds.length - toUpdate.length,
      } as Prisma.InputJsonValue,
    });

    for (const userId of toUpdate) {
      this.userEventsService.emitUserUpdated(userId);
    }
    return { updatedCount: toUpdate.length, skippedCount: dto.userIds.length - toUpdate.length };
  }
}
