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
import { PatchAdminUserDto } from '../dto/patch-admin-user.dto';
import { PatchAdminUserRoleDto } from '../dto/patch-admin-user-role.dto';
import { AuthSessionRevocationService } from '../../auth/services/auth-session-revocation.service';
import { UserAuthSnapshotCacheService } from '../../auth/services/user-auth-snapshot-cache.service';
import { AccountErasureService } from '../../auth/services/account-erasure.service';
import { AdminUsersStatusHistoryService } from './admin-users-status-history.service';

@Injectable()
export class AdminUsersWriteService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly userEventsService: UserEventsService,
    private readonly sessionRevocation: AuthSessionRevocationService,
    private readonly authSnapshotCache: UserAuthSnapshotCacheService,
    private readonly accountErasure: AccountErasureService,
    private readonly statusHistory: AdminUsersStatusHistoryService,
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
      await this.statusHistory.recordStatusAction({
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
}
