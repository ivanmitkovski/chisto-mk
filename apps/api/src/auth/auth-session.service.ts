import { Inject, Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { JwtService } from '@nestjs/jwt';
import { randomBytes } from 'crypto';
import * as bcrypt from 'bcrypt';
import { User, UserSession, UserStatus } from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import { ReportsUploadService } from '../reports/reports-upload.service';
import { AuditService } from '../audit/audit.service';
import { AuthResponse } from './types/auth-response.type';
import { AUTH_ENV_RUNTIME, REMEMBER_ME_SHORT_DAYS, type AuthEnvRuntime } from './auth-env.config';
import { AuthSessionRevocationService } from './auth-session-revocation.service';
import type { AuthenticatedUser } from './types/authenticated-user.type';
import { recordAuditWriteFailure } from '../common/audit/audit-log-failure.util';
import { AuthRefreshReplayCacheService } from './auth-refresh-replay-cache.service';
import { buildAuthResponsePayload } from './auth-response.factory';

type SessionWithUser = UserSession & { user: User };
type BuildAuthOptions = { deviceId?: string | undefined; sessionId?: string | undefined };

@Injectable()
export class AuthSessionService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
    private readonly reportsUploadService: ReportsUploadService,
    private readonly audit: AuditService,
    private readonly eventEmitter: EventEmitter2,
    private readonly sessionRevocation: AuthSessionRevocationService,
    @Inject(AUTH_ENV_RUNTIME) private readonly env: AuthEnvRuntime,
    private readonly configService: ConfigService,
    private readonly replayCache: AuthRefreshReplayCacheService,
  ) {}

  async refresh(rawRefreshToken: string, deviceId?: string): Promise<AuthResponse> {
    const tokenId = this.parseTokenIdFromRefreshToken(rawRefreshToken);
    if (!tokenId) {
      this.throwInvalidRefreshToken();
    }

    const session = await this.prisma.userSession.findUnique({
      where: { tokenId },
      include: { user: true },
    });

    if (!session || session.expiresAt <= new Date()) {
      this.throwInvalidRefreshToken();
    }

    if (session.user.status !== UserStatus.ACTIVE) {
      throw new UnauthorizedException({
        code: 'ACCOUNT_SUSPENDED',
        message: 'Account is not active',
      });
    }

    const hashOk = await bcrypt.compare(rawRefreshToken, session.refreshTokenHash);

    if (session.revokedAt != null) {
      if (hashOk) await this.auditRefreshTokenReuse(session, tokenId);
      this.throwInvalidRefreshToken();
    }

    if (!hashOk) {
      const replay = await this.tryReplayPreviousRefreshToken(session, rawRefreshToken);
      if (replay) return replay;
      this.throwInvalidRefreshToken();
    }

    return this.rotateSessionInPlace(session, rawRefreshToken, true, deviceId);
  }

  async logout(rawRefreshToken: string): Promise<void> {
    const tokenId = this.parseTokenIdFromRefreshToken(rawRefreshToken);
    if (!tokenId) return;

    const session = await this.prisma.userSession.findUnique({
      where: { tokenId },
    });
    if (
      !session ||
      session.revokedAt != null ||
      session.expiresAt <= new Date() ||
      !(await bcrypt.compare(rawRefreshToken, session.refreshTokenHash))
    ) {
      return;
    }
    await this.prisma.userSession.update({
      where: { id: session.id },
      data: { revokedAt: new Date() },
    });
  }

  async buildAuthResponse(
    user: User,
    rememberMe = true,
    options: BuildAuthOptions = {},
  ): Promise<AuthResponse> {
    const deviceId = this.normalizeDeviceId(options.deviceId);
    if (options.sessionId) {
      const existingSession = await this.prisma.userSession.findUnique({
        where: { id: options.sessionId },
        include: { user: true },
      });
      if (existingSession) {
        return this.issueTokensForExistingSession(existingSession, rememberMe, deviceId);
      }
    }

    if (deviceId) {
      const existingDeviceSession = await this.prisma.userSession.findFirst({
        where: { userId: user.id, deviceId },
        orderBy: { createdAt: 'desc' },
        include: { user: true },
      });
      if (existingDeviceSession) {
        return this.issueTokensForExistingSession(existingDeviceSession, rememberMe, deviceId);
      }
    }

    await this.enforceSessionCap(user.id, deviceId);

    const tokenId = randomBytes(16).toString('hex');
    const tokenSecret = randomBytes(20).toString('hex');
    const fullRefreshToken = `${tokenId}.${tokenSecret}`;
    const refreshTokenHash = await bcrypt.hash(fullRefreshToken, this.env.saltRounds);

    const refreshDays = rememberMe ? this.env.refreshTokenTtlDays : REMEMBER_ME_SHORT_DAYS;
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + refreshDays);

    const session = await this.prisma.userSession.create({
      data: {
        userId: user.id,
        tokenId,
        refreshTokenHash,
        previousTokenHash: null,
        rotatedAt: null,
        deviceId: deviceId ?? null,
        expiresAt,
      },
    });

    return this.signAuthResponse(user, session.id, fullRefreshToken);
  }

  async revokeOthersForCurrentUser(user: AuthenticatedUser): Promise<{ revoked: number }> {
    return this.sessionRevocation.revokeOthersForUser(user, 'user_revoke_others');
  }

  private async rotateSessionInPlace(
    session: SessionWithUser,
    rawRefreshToken: string,
    rememberMe: boolean,
    deviceId?: string,
  ): Promise<AuthResponse> {
    const oldRefreshTokenHash = session.refreshTokenHash;
    const tokenSecret = randomBytes(20).toString('hex');
    const fullRefreshToken = `${session.tokenId}.${tokenSecret}`;
    const refreshTokenHash = await bcrypt.hash(fullRefreshToken, this.env.saltRounds);
    const expiresAt = this.refreshExpiresAt(rememberMe);
    const response = await this.signAuthResponse(session.user, session.id, fullRefreshToken);
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
      this.throwInvalidRefreshToken();
    }

    await this.replayCache.set(
      oldRefreshTokenHash,
      response,
      this.env.refreshTokenRotationGraceSeconds,
    );
    return response;
  }

  private async tryReplayPreviousRefreshToken(
    session: SessionWithUser,
    rawRefreshToken: string,
  ): Promise<AuthResponse | null> {
    if (!session.previousTokenHash || !session.rotatedAt) return null;
    if (!(await bcrypt.compare(rawRefreshToken, session.previousTokenHash))) return null;

    const graceMs = this.env.refreshTokenRotationGraceSeconds * 1000;
    const ageMs = Date.now() - session.rotatedAt.getTime();
    if (ageMs > graceMs) {
      await this.prisma.userSession.update({
        where: { id: session.id },
        data: { revokedAt: new Date() },
      });
      await this.auditRefreshTokenReuse(session, session.tokenId);
      return null;
    }

    const replay = await this.replayCache.get(session.previousTokenHash);
    if (replay) return replay;

    await new Promise((resolve) => setTimeout(resolve, 50));
    return this.replayCache.get(session.previousTokenHash);
  }

  private async issueTokensForExistingSession(
    session: SessionWithUser,
    rememberMe: boolean,
    deviceId?: string,
  ): Promise<AuthResponse> {
    const tokenSecret = randomBytes(20).toString('hex');
    const fullRefreshToken = `${session.tokenId}.${tokenSecret}`;
    const refreshTokenHash = await bcrypt.hash(fullRefreshToken, this.env.saltRounds);
    const expiresAt = this.refreshExpiresAt(rememberMe);
    await this.prisma.userSession.update({
      where: { id: session.id },
      data: {
        refreshTokenHash,
        previousTokenHash: null,
        rotatedAt: null,
        expiresAt,
        revokedAt: null,
        ...(deviceId ? { deviceId } : {}),
      },
    });
    return this.signAuthResponse(session.user, session.id, fullRefreshToken);
  }

  private async enforceSessionCap(userId: string, incomingDeviceId: string | undefined): Promise<void> {
    const activeSessions = await this.prisma.userSession.findMany({
      where: {
        userId,
        revokedAt: null,
        expiresAt: { gt: new Date() },
      },
      orderBy: { createdAt: 'asc' },
      select: { id: true, deviceId: true },
    });
    const activeKeys = new Set(
      activeSessions.map((session) => session.deviceId ?? `legacy:${session.id}`),
    );
    const incomingKey = incomingDeviceId ?? `legacy:new:${randomBytes(8).toString('hex')}`;
    const countAfterLogin = activeKeys.has(incomingKey) ? activeKeys.size : activeKeys.size + 1;
    if (countAfterLogin <= this.env.maxSessionsPerUser) return;

    const toRevokeCount = countAfterLogin - this.env.maxSessionsPerUser;
    const toRevoke = activeSessions.slice(0, toRevokeCount);
    const now = new Date();
    await Promise.all(
      toRevoke.map((session) =>
        this.prisma.userSession.update({
          where: { id: session.id },
          data: { revokedAt: now },
        }),
      ),
    );
  }

  private async signAuthResponse(
    user: User,
    sessionId: string,
    fullRefreshToken: string,
  ): Promise<AuthResponse> {
    return buildAuthResponsePayload(user, sessionId, fullRefreshToken, {
      jwtService: this.jwtService,
      reportsUploadService: this.reportsUploadService,
      configService: this.configService,
      env: this.env,
    });
  }

  private refreshExpiresAt(rememberMe: boolean): Date {
    const refreshDays = rememberMe ? this.env.refreshTokenTtlDays : REMEMBER_ME_SHORT_DAYS;
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + refreshDays);
    return expiresAt;
  }

  private async auditRefreshTokenReuse(
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

  private normalizeDeviceId(deviceId?: string): string | undefined {
    const normalized = deviceId?.trim();
    if (!normalized) return undefined;
    return normalized.slice(0, 128);
  }

  private throwInvalidRefreshToken(): never {
    throw new UnauthorizedException({
      code: 'INVALID_REFRESH_TOKEN',
      message: 'Refresh token is invalid or expired',
    });
  }

  private parseTokenIdFromRefreshToken(fullToken: string): string | null {
    const dotIndex = fullToken.indexOf('.');
    if (dotIndex <= 0 || dotIndex === fullToken.length - 1) return null;
    return fullToken.slice(0, dotIndex);
  }
}
