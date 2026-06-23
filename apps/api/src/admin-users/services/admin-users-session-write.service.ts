import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { Prisma, Role } from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';
import type { AuthenticatedUser } from '../../auth/types/authenticated-user.type';
import { AuditService } from '../../audit/services/audit.service';
import { UserEventsService } from '../../admin-realtime/services/user-events.service';
import { AuthSessionRevocationService } from '../../auth/services/auth-session-revocation.service';
import { UserAuthSnapshotCacheService } from '../../auth/services/user-auth-snapshot-cache.service';

@Injectable()
export class AdminUsersSessionWriteService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly userEventsService: UserEventsService,
    private readonly sessionRevocation: AuthSessionRevocationService,
    private readonly authSnapshotCache: UserAuthSnapshotCacheService,
  ) {}

  private async assertCanManageUser(userId: string, actor: AuthenticatedUser): Promise<void> {
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
        message: 'Only a super admin can manage this account',
      });
    }
  }

  async revokeSession(
    userId: string,
    sessionId: string,
    actor: AuthenticatedUser,
  ): Promise<{ ok: true }> {
    await this.assertCanManageUser(userId, actor);
    return this.sessionRevocation.revokeSessionForUser(userId, sessionId, actor.userId);
  }

  async revokeAllSessions(userId: string, actor: AuthenticatedUser): Promise<{ ok: true }> {
    await this.assertCanManageUser(userId, actor);

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
}
