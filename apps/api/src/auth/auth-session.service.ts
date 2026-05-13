import { Inject, Injectable, UnauthorizedException } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { JwtService } from '@nestjs/jwt';
import { randomBytes } from 'crypto';
import * as bcrypt from 'bcrypt';
import { User, UserStatus } from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import { ReportsUploadService } from '../reports/reports-upload.service';
import { AuditService } from '../audit/audit.service';
import { AuthResponse } from './types/auth-response.type';
import { AUTH_ENV_RUNTIME, REMEMBER_ME_SHORT_DAYS, type AuthEnvRuntime } from './auth-env.config';

@Injectable()
export class AuthSessionService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
    private readonly reportsUploadService: ReportsUploadService,
    private readonly audit: AuditService,
    private readonly eventEmitter: EventEmitter2,
    @Inject(AUTH_ENV_RUNTIME) private readonly env: AuthEnvRuntime,
  ) {}

  async refresh(rawRefreshToken: string): Promise<AuthResponse> {
    const tokenId = this.parseTokenIdFromRefreshToken(rawRefreshToken);
    if (!tokenId) {
      throw new UnauthorizedException({
        code: 'INVALID_REFRESH_TOKEN',
        message: 'Refresh token is invalid or expired',
      });
    }

    const session = await this.prisma.userSession.findUnique({
      where: { tokenId },
      include: { user: true },
    });

    if (!session || session.expiresAt <= new Date()) {
      throw new UnauthorizedException({
        code: 'INVALID_REFRESH_TOKEN',
        message: 'Refresh token is invalid or expired',
      });
    }

    const hashOk = await bcrypt.compare(rawRefreshToken, session.refreshTokenHash);

    if (session.revokedAt != null) {
      if (hashOk) {
        await this.revokeAllSessionsForUserInternal(session.userId);
        await this.audit
          .log({
            actorId: session.userId,
            action: 'REFRESH_TOKEN_REUSE_DETECTED',
            resourceType: 'UserSession',
            resourceId: session.id,
            metadata: { tokenId },
          })
          .catch(() => {});
        this.eventEmitter.emit('security.refresh_token_reuse', { userId: session.userId });
      }
      throw new UnauthorizedException({
        code: 'INVALID_REFRESH_TOKEN',
        message: 'Refresh token is invalid or expired',
      });
    }

    if (!hashOk) {
      throw new UnauthorizedException({
        code: 'INVALID_REFRESH_TOKEN',
        message: 'Refresh token is invalid or expired',
      });
    }

    await this.prisma.userSession.update({
      where: { id: session.id },
      data: { revokedAt: new Date() },
    });

    const { user } = session;
    if (user.status !== UserStatus.ACTIVE) {
      throw new UnauthorizedException({
        code: 'ACCOUNT_SUSPENDED',
        message: 'Account is not active',
      });
    }

    return this.buildAuthResponse(user, true);
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

  async buildAuthResponse(user: User, rememberMe = true): Promise<AuthResponse> {
    const tokenId = randomBytes(16).toString('hex');
    const tokenSecret = randomBytes(20).toString('hex');
    const fullRefreshToken = `${tokenId}.${tokenSecret}`;
    const refreshTokenHash = await bcrypt.hash(fullRefreshToken, this.env.saltRounds);

    const refreshDays = rememberMe ? this.env.refreshTokenTtlDays : REMEMBER_ME_SHORT_DAYS;
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + refreshDays);

    const activeCount = await this.prisma.userSession.count({
      where: {
        userId: user.id,
        revokedAt: null,
        expiresAt: { gt: new Date() },
      },
    });
    if (activeCount >= this.env.maxSessionsPerUser) {
      const toRevokeCount = activeCount - this.env.maxSessionsPerUser + 1;
      const toRevoke = await this.prisma.userSession.findMany({
        where: {
          userId: user.id,
          revokedAt: null,
          expiresAt: { gt: new Date() },
        },
        orderBy: { createdAt: 'asc' },
        take: toRevokeCount,
        select: { id: true },
      });
      const now = new Date();
      await Promise.all(
        toRevoke.map((s: { id: string }) =>
          this.prisma.userSession.update({
            where: { id: s.id },
            data: { revokedAt: now },
          }),
        ),
      );
    }

    const session = await this.prisma.userSession.create({
      data: {
        userId: user.id,
        tokenId,
        refreshTokenHash,
        expiresAt,
      },
    });

    const accessToken = this.jwtService.sign(
      {
        sub: user.id,
        email: user.email,
        phoneNumber: user.phoneNumber,
        role: user.role,
        sid: session.id,
      },
      {
        expiresIn: this.env.accessTokenTtl,
        issuer: 'chisto-api',
        audience: 'chisto-api',
      },
    );

    const avatarUrl = await this.reportsUploadService.signPrivateObjectKey(user.avatarObjectKey);

    return {
      accessToken,
      refreshToken: fullRefreshToken,
      user: {
        id: user.id,
        firstName: user.firstName,
        lastName: user.lastName,
        email: user.email,
        phoneNumber: user.phoneNumber,
        role: user.role,
        status: user.status,
        isPhoneVerified: user.isPhoneVerified,
        pointsBalance: user.pointsBalance,
        avatarUrl,
        organizerCertifiedAt: user.organizerCertifiedAt?.toISOString() ?? null,
      },
    };
  }

  private async revokeAllSessionsForUserInternal(userId: string): Promise<void> {
    const now = new Date();
    await this.prisma.userSession.updateMany({
      where: { userId, revokedAt: null },
      data: { revokedAt: now },
    });
  }

  private parseTokenIdFromRefreshToken(fullToken: string): string | null {
    const dotIndex = fullToken.indexOf('.');
    if (dotIndex <= 0 || dotIndex === fullToken.length - 1) return null;
    return fullToken.slice(0, dotIndex);
  }
}
