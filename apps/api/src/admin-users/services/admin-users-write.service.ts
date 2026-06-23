import {
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma, Role, UserStatus } from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';
import { UserEventsService } from '../../admin-realtime/services/user-events.service';
import type { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { AuditService } from '../../audit/services/audit.service';
import { BulkAdminUsersDto } from '../dto/bulk-admin-users.dto';
import { PatchAdminUserDto } from '../dto/patch-admin-user.dto';
import { PatchAdminUserRoleDto } from '../dto/patch-admin-user-role.dto';
import { AuthSessionRevocationService } from '../../auth/services/auth-session-revocation.service';
import { UserAuthSnapshotCacheService } from '../../auth/services/user-auth-snapshot-cache.service';
import { AccountErasureService } from '../../auth/services/account-erasure.service';

@Injectable()
export class AdminUsersWriteService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly userEventsService: UserEventsService,
    private readonly sessionRevocation: AuthSessionRevocationService,
    private readonly authSnapshotCache: UserAuthSnapshotCacheService,
    private readonly accountErasure: AccountErasureService,
  ) {}

  async patch(
    id: string,
    dto: PatchAdminUserDto,
    actor: AuthenticatedUser,
  ): Promise<{ id: string; role: Role; status: UserStatus }> {
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
    if (dto.status != null && dto.status !== UserStatus.DELETED) {
      data.status = dto.status;
    }

    const shouldErase = dto.status === UserStatus.DELETED && target.status !== UserStatus.DELETED;

    if (Object.keys(data).length === 0 && !shouldErase) {
      const u = await this.prisma.user.findUniqueOrThrow({
        where: { id },
        select: { id: true, firstName: true, lastName: true, phoneNumber: true, role: true, status: true },
      });
      return u;
    }

    if (shouldErase) {
      if (Object.keys(data).length > 0) {
        await this.prisma.user.update({ where: { id }, data });
      }
      await this.accountErasure.eraseUserAccount(id);
    } else {
      await this.prisma.user.update({
        where: { id },
        data,
      });
      if (dto.status === UserStatus.SUSPENDED) {
        await this.sessionRevocation.revokeAllForUser(id, 'status_changed');
      }
    }

    const updated = await this.prisma.user.findUniqueOrThrow({
      where: { id },
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
      changes.status = { from: target.status, to: shouldErase ? UserStatus.DELETED : dto.status };
    }

    if (dto.status != null && dto.status !== target.status && !shouldErase) {
      await this.recordStatusAction({
        userId: id,
        actorId: actor.userId,
        fromStatus: target.status,
        toStatus: dto.status,
        reasonCode: dto.reasonCode ?? 'admin_action',
        note: dto.note ?? null,
      });
    }

    await this.audit.log({
      actorId: actor.userId,
      action: 'USER_UPDATED',
      resourceType: 'User',
      resourceId: id,
      metadata: { before: target, after: updated, changes } as Prisma.InputJsonValue,
    });

    this.authSnapshotCache.invalidate(id);
    this.userEventsService.emitUserUpdated(id);
    return updated;
  }

  async patchRole(
    id: string,
    dto: PatchAdminUserRoleDto,
    actor: AuthenticatedUser,
  ): Promise<{ id: string; role: Role; status: UserStatus }> {
    if (actor.userId === id && dto.role !== actor.role) {
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

    const updated = await this.prisma.user.update({
      where: { id },
      data: { role: dto.role },
      select: { id: true, firstName: true, lastName: true, phoneNumber: true, role: true, status: true },
    });

    await this.audit.log({
      actorId: actor.userId,
      action: 'USER_ROLE_CHANGED',
      resourceType: 'User',
      resourceId: id,
      metadata: {
        fromRole: target.role,
        toRole: dto.role,
      } as Prisma.InputJsonValue,
    });

    this.authSnapshotCache.invalidate(id);
    this.userEventsService.emitUserUpdated(id);
    return updated;
  }

  async bulk(dto: BulkAdminUsersDto, actor: AuthenticatedUser) {
    if (dto.action === 'changeRole' && actor.role !== Role.SUPER_ADMIN) {
      throw new ForbiddenException({
        code: 'FORBIDDEN',
        message: 'Only a super admin can change roles in bulk',
      });
    }
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
      select: { id: true, role: true, status: true },
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

    if (statusUpdate != null) {
      for (const row of targets) {
        if (!toUpdate.includes(row.id)) continue;
        if (row.status === statusUpdate) continue;
        await this.recordStatusAction({
          userId: row.id,
          actorId: actor.userId,
          fromStatus: row.status,
          toStatus: statusUpdate,
          reasonCode: dto.reasonCode ?? 'bulk_admin_action',
          note: dto.note ?? null,
        });
      }
    }

    if (dto.action === 'suspend') {
      for (const userId of toUpdate) {
        await this.sessionRevocation.revokeAllForUser(userId, 'status_changed');
        this.authSnapshotCache.invalidate(userId);
      }
    } else {
      for (const userId of toUpdate) {
        this.authSnapshotCache.invalidate(userId);
      }
    }

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

  async revokeSession(
    userId: string,
    sessionId: string,
    actor: AuthenticatedUser,
  ): Promise<{ ok: true }> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, role: true },
    });
    if (!user) {
      throw new NotFoundException({
        code: 'USER_NOT_FOUND',
        message: 'User not found',
      });
    }
    if (user.role === Role.SUPER_ADMIN && actor.role !== Role.SUPER_ADMIN) {
      throw new ForbiddenException({
        code: 'FORBIDDEN',
        message: 'Only a super admin can revoke sessions for this account',
      });
    }
    return this.sessionRevocation.revokeSessionForUser(userId, sessionId, actor.userId);
  }

  async revokeAllSessions(userId: string, actor: AuthenticatedUser): Promise<{ ok: true }> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, role: true },
    });
    if (!user) {
      throw new NotFoundException({
        code: 'USER_NOT_FOUND',
        message: 'User not found',
      });
    }
    if (user.role === Role.SUPER_ADMIN && actor.role !== Role.SUPER_ADMIN) {
      throw new ForbiddenException({
        code: 'FORBIDDEN',
        message: 'Only a super admin can revoke sessions for this account',
      });
    }

    await this.sessionRevocation.revokeAllForUser(userId, 'admin_action');

    await this.audit.log({
      actorId: actor.userId,
      action: 'USER_SESSIONS_REVOKED_ALL',
      resourceType: 'User',
      resourceId: userId,
      metadata: {} as Prisma.InputJsonValue,
    });

    this.authSnapshotCache.invalidate(userId);
    this.userEventsService.emitUserUpdated(userId);
    return { ok: true };
  }

  async createModerationNote(
    userId: string,
    body: string,
    actor: AuthenticatedUser,
  ): Promise<{ id: string; createdAt: string; body: string; authorEmail: string; authorName: string }> {
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

    const note = await this.prisma.userModerationNote.create({
      data: {
        userId,
        authorId: actor.userId,
        body: body.trim(),
      },
      select: { id: true, createdAt: true },
    });

    return {
      id: note.id,
      createdAt: note.createdAt.toISOString(),
      body: body.trim(),
      authorEmail: actor.email,
      authorName: actor.email,
    };
  }

  private async recordStatusAction(input: {
    userId: string;
    actorId: string;
    fromStatus: UserStatus;
    toStatus: UserStatus;
    reasonCode: string;
    note: string | null;
  }): Promise<void> {
    await this.prisma.userStatusAction.create({
      data: {
        userId: input.userId,
        actorId: input.actorId,
        fromStatus: input.fromStatus,
        toStatus: input.toStatus,
        reasonCode: input.reasonCode,
        note: input.note,
      },
    });
  }
}
