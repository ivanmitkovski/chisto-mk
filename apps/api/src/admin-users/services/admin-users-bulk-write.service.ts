import {
  ConflictException,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { Prisma, Role, UserStatus } from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';
import type { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { AuditService } from '../../audit/services/audit.service';
import { BulkAdminUsersDto } from '../dto/bulk-admin-users.dto';
import { UserEventsService } from '../../admin-realtime/services/user-events.service';
import { AuthSessionRevocationService } from '../../auth/services/auth-session-revocation.service';
import { UserAuthSnapshotCacheService } from '../../auth/services/user-auth-snapshot-cache.service';
import { AdminUsersStatusHistoryService } from './admin-users-status-history.service';

@Injectable()
export class AdminUsersBulkWriteService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly userEventsService: UserEventsService,
    private readonly sessionRevocation: AuthSessionRevocationService,
    private readonly authSnapshotCache: UserAuthSnapshotCacheService,
    private readonly statusHistory: AdminUsersStatusHistoryService,
  ) {}

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
        await this.statusHistory.recordStatusAction({
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
}
