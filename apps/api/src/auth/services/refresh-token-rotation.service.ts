import { Inject, Injectable } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { randomBytes } from 'crypto';
import * as bcrypt from 'bcrypt';
import { User, UserSession } from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';
import { AuditService } from '../../audit/services/audit.service';
import { AUTH_ENV_RUNTIME, type AuthEnvRuntime } from '../constants/auth-env.config';
import { AuthSessionRevocationService } from './auth-session-revocation.service';
import { AuthRefreshReplayCacheService } from './auth-refresh-replay-cache.service';
import { recordAuditWriteFailure } from '../../common/audit/audit-log-failure.util';
import type { AuthResponse } from '../types/auth-response.type';

type SessionWithUser = UserSession & { user: User };

@Injectable()
export class RefreshTokenRotationService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly eventEmitter: EventEmitter2,
    private readonly sessionRevocation: AuthSessionRevocationService,
    @Inject(AUTH_ENV_RUNTIME) private readonly env: AuthEnvRuntime,
    private readonly replayCache: AuthRefreshReplayCacheService,
  ) {}

  async rotateSessionInPlace(
    session: SessionWithUser,
    rawRefreshToken: string,
    rememberMe: boolean,
    deviceId: string | undefined,
    signAuthResponse: (
      user: User,
      sessionId: string,
      fullRefreshToken: string,
    ) => Promise<AuthResponse>,
    throwInvalidRefreshToken: () => never,
  ): Promise<AuthResponse> {
    const oldRefreshTokenHash = session.refreshTokenHash;
    const tokenSecret = randomBytes(20).toString('hex');
    const fullRefreshToken = `${session.tokenId}.${tokenSecret}`;
    const refreshTokenHash = await bcrypt.hash(fullRefreshToken, this.env.saltRounds);
    const expiresAt = this.refreshExpiresAt(rememberMe);
    const response = await signAuthResponse(session.user, session.id, fullRefreshToken);
    const normalizedDeviceId = this.normalizeDeviceId(deviceId);
    const now = new Date();
    const update = await this.prisma.userSession.updateMany({
      where: {
        id: session.id,
        revokedAt: null,
        refreshTokenHash: oldRefreshTokenHash,
      },
      data: {
        refreshTokenHash,
        previousTokenHash: oldRefreshTokenHash,
        rotatedAt: now,
        expiresAt,
        rememberMe,
        deviceId: normalizedDeviceId ?? session.deviceId,
      },
    });

    if (update.count === 0) {
      const refreshed = await this.prisma.userSession.findUnique({
        where: { id: session.id },
        include: { user: true },
      });
      if (refreshed) {
        const replay = await this.tryReplayPreviousRefreshToken(refreshed, rawRefreshToken);
        if (replay) return replay;
      }
      throwInvalidRefreshToken();
    }

    await this.replayCache.set(
      oldRefreshTokenHash,
      response,
      this.env.refreshTokenRotationGraceSeconds,
    );
    return response;
  }

  async tryReplayPreviousRefreshToken(
    session: SessionWithUser,
    rawRefreshToken: string,
  ): Promise<AuthResponse | null> {
    if (!session.previousTokenHash || !session.rotatedAt) return null;
    if (!(await bcrypt.compare(rawRefreshToken, session.previousTokenHash))) return null;

    const graceMs = this.env.refreshTokenRotationGraceSeconds * 1000;
    const ageMs = Date.now() - session.rotatedAt.getTime();
    if (ageMs > graceMs) {
      await this.sessionRevocation.revokeSession(
        session.id,
        session.userId,
        'refresh_token_reuse',
      );
      await this.auditRefreshTokenReuse(session, session.tokenId);
      return null;
    }

    const replay = await this.replayCache.get(session.previousTokenHash);
    if (replay) return replay;

    await new Promise((resolve) => setTimeout(resolve, 50));
    return this.replayCache.get(session.previousTokenHash);
  }

  private refreshExpiresAt(rememberMe: boolean): Date {
    const refreshDays = rememberMe ? this.env.refreshTokenTtlDays : this.env.refreshTokenStandardDays;
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + refreshDays);
    return expiresAt;
  }

  private normalizeDeviceId(deviceId?: string): string | undefined {
    const normalized = deviceId?.trim();
    if (!normalized) return undefined;
    return normalized.slice(0, 128);
  }

  async auditRefreshTokenReuse(
    session: { id: string; userId: string },
    tokenId: string,
  ): Promise<void> {
    await this.audit
      .log({
        actorId: session.userId,
        action: 'REFRESH_TOKEN_REUSE_DETECTED',
        resourceType: 'UserSession',
        resourceId: session.id,
        metadata: { tokenId },
      })
      .catch((err) => recordAuditWriteFailure('REFRESH_TOKEN_REUSE_DETECTED', err));
    this.eventEmitter.emit('security.refresh_token_reuse', {
      userId: session.userId,
      sessionId: session.id,
    });
  }
}
