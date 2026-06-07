import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditService } from '../../audit/services/audit.service';
import type { AuthenticatedUser } from '../types/authenticated-user.type';
import { UserAuthSnapshotCacheService } from './user-auth-snapshot-cache.service';

export type SessionRevokeReason =
  | 'password_changed'
  | 'role_changed'
  | 'status_changed'
  | 'admin_action'
  | 'user_revoke_others'
  | 'refresh_token_reuse'
  | 'account_deleted';

@Injectable()
export class AuthSessionRevocationService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly eventEmitter: EventEmitter2,
    private readonly authSnapshotCache: UserAuthSnapshotCacheService,
  ) {}

  async revokeAllForUser(userId: string, reason: SessionRevokeReason): Promise<number> {
    const now = new Date();
    const result = await this.prisma.userSession.updateMany({
      where: { userId, revokedAt: null },
      data: { revokedAt: now },
    });
    this.authSnapshotCache.invalidate(userId);
    this.eventEmitter.emit('security.sessions_revoked', { userId, reason });
    await this.audit
      .log({
        actorId: userId,
        action: 'SESSIONS_REVOKED_ALL',
        resourceType: 'User',
        resourceId: userId,
        metadata: { reason, count: result.count },
      })
      .catch(() => {});
    return result.count;
  }

  async revokeOthersForUser(
    user: AuthenticatedUser,
    reason: SessionRevokeReason = 'user_revoke_others',
  ): Promise<{ revoked: number }> {
    if (!user.sessionId) {
      throw new BadRequestException({
        code: 'SESSION_CONTEXT_REQUIRED',
        message: 'Sign in again to manage sessions',
      });
    }
    const now = new Date();
    const result = await this.prisma.userSession.updateMany({
      where: {
        userId: user.userId,
        id: { not: user.sessionId },
        revokedAt: null,
      },
      data: { revokedAt: now },
    });
    await this.audit.log({
      actorId: user.userId,
      action: 'SESSION_REVOKE_OTHERS',
      resourceType: 'UserSession',
      resourceId: user.sessionId,
      metadata: { count: result.count, reason },
    });
    return { revoked: result.count };
  }

  async revokeSessionForUser(
    userId: string,
    sessionId: string,
    actorId: string,
    reason: SessionRevokeReason = 'admin_action',
  ): Promise<{ ok: true }> {
    const session = await this.prisma.userSession.findFirst({
      where: { id: sessionId, userId },
      select: { id: true, revokedAt: true },
    });
    if (!session) {
      throw new NotFoundException({
        code: 'SESSION_NOT_FOUND',
        message: 'Session not found',
      });
    }
    if (session.revokedAt != null) {
      return { ok: true };
    }

    const now = new Date();
    await this.prisma.userSession.update({
      where: { id: sessionId },
      data: { revokedAt: now },
    });
    this.authSnapshotCache.invalidate(userId);
    this.eventEmitter.emit('security.sessions_revoked', { userId, reason });
    await this.audit.log({
      actorId,
      action: 'SESSION_REVOKED_BY_ADMIN',
      resourceType: 'UserSession',
      resourceId: sessionId,
      metadata: { userId, reason },
    });
    return { ok: true };
  }
}
