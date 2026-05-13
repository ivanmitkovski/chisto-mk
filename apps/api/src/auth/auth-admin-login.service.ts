import { Inject, Injectable, UnauthorizedException } from '@nestjs/common';
import { randomBytes } from 'crypto';
import * as bcrypt from 'bcrypt';
import { verify as verifyTotp } from 'otplib';
import { UserStatus } from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import { AdminLoginDto } from './dto/admin-login.dto';
import { AdminLoginResponse, AuthResponse } from './types/auth-response.type';
import { AuditService } from '../audit/audit.service';
import { AuthSessionService } from './auth-session.service';
import {
  ADMIN_TEMP_TOKEN_EXPIRES_SECONDS,
  LOGIN_LOCKOUT_WINDOW_MINUTES,
  LOGIN_MAX_ATTEMPTS,
} from './auth.constants';
import { AUTH_ENV_RUNTIME, type AuthEnvRuntime } from './auth-env.config';
import { ADMIN_PANEL_ROLES } from './admin-roles';

@Injectable()
export class AuthAdminLoginService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly audit: AuditService,
    private readonly sessionService: AuthSessionService,
    @Inject(AUTH_ENV_RUNTIME) private readonly env: AuthEnvRuntime,
  ) {}

  async adminLogin(dto: AdminLoginDto): Promise<AdminLoginResponse> {
    const email = dto.email.toLowerCase().trim();

    const failure = await this.prisma.adminLoginFailure.findUnique({
      where: { email },
    });
    const now = new Date();
    const windowMs = LOGIN_LOCKOUT_WINDOW_MINUTES * 60 * 1000;
    if (
      failure &&
      failure.attemptCount >= LOGIN_MAX_ATTEMPTS &&
      failure.firstFailedAt.getTime() > now.getTime() - windowMs
    ) {
      const unlockAt = new Date(failure.firstFailedAt.getTime() + windowMs);
      const retryAfterSeconds = Math.max(0, Math.ceil((unlockAt.getTime() - now.getTime()) / 1000));
      throw new UnauthorizedException({
        code: 'TOO_MANY_ATTEMPTS',
        message: 'Too many failed attempts. Try again later.',
        details: { retryAfterSeconds },
      });
    }

    const user = await this.prisma.user.findUnique({
      where: { email },
    });

    if (!user) {
      await this.recordAdminLoginFailure(email);
      throw new UnauthorizedException({
        code: 'INVALID_CREDENTIALS',
        message: 'Invalid email or password',
      });
    }

    const passwordOk = await bcrypt.compare(dto.password, user.passwordHash);
    if (!passwordOk) {
      await this.recordAdminLoginFailure(email);
      throw new UnauthorizedException({
        code: 'INVALID_CREDENTIALS',
        message: 'Invalid email or password',
      });
    }

    if (!ADMIN_PANEL_ROLES.includes(user.role)) {
      await this.recordAdminLoginFailure(email);
      throw new UnauthorizedException({
        code: 'INVALID_CREDENTIALS',
        message: 'Invalid email or password',
      });
    }

    if (user.status !== UserStatus.ACTIVE) {
      await this.recordAdminLoginFailure(email);
      throw new UnauthorizedException({
        code: 'ACCOUNT_SUSPENDED',
        message: 'Account is not active',
      });
    }

    if (user.totpSecret) {
      const tempToken = randomBytes(32).toString('hex');
      const tokenHash = await bcrypt.hash(tempToken, this.env.saltRounds);
      const expiresAt = new Date();
      expiresAt.setSeconds(expiresAt.getSeconds() + ADMIN_TEMP_TOKEN_EXPIRES_SECONDS);

      await this.prisma.adminTempToken.create({
        data: {
          tokenHash,
          userId: user.id,
          email,
          expiresAt,
        },
      });

      return {
        requiresTotp: true,
        tempToken,
        expiresIn: ADMIN_TEMP_TOKEN_EXPIRES_SECONDS,
      };
    }

    await this.clearAdminLoginFailures(email);
    await this.audit
      .log({
        actorId: user.id,
        action: 'ADMIN_LOGIN_SUCCESS',
        resourceType: 'User',
        resourceId: user.id,
        metadata: { email },
      })
      .catch(() => {});

    return this.sessionService.buildAuthResponse(user, true);
  }

  async completeAdmin2FALogin(tempToken: string, code: string): Promise<AuthResponse> {
    const trimmedToken = tempToken.trim();
    const trimmedCode = code.trim();
    if (!trimmedToken || !trimmedCode) {
      throw new UnauthorizedException({
        code: 'INVALID_TEMP_TOKEN',
        message: 'Invalid or expired login session',
      });
    }

    const candidates = await this.prisma.adminTempToken.findMany({
      where: { expiresAt: { gt: new Date() } },
      include: { user: true },
      take: 50,
      orderBy: { createdAt: 'desc' },
    });

    let matched: (typeof candidates)[number] | null = null;
    for (const row of candidates) {
      if (await bcrypt.compare(trimmedToken, row.tokenHash)) {
        matched = row;
        break;
      }
    }

    if (!matched) {
      throw new UnauthorizedException({
        code: 'INVALID_TEMP_TOKEN',
        message: 'Invalid or expired login session',
      });
    }

    const { user } = matched;
    if (!user.totpSecret) {
      await this.prisma.adminTempToken.delete({ where: { id: matched.id } }).catch(() => {});
      throw new UnauthorizedException({
        code: 'INVALID_TEMP_TOKEN',
        message: 'Invalid or expired login session',
      });
    }

    const totpResult = await verifyTotp({
      token: trimmedCode,
      secret: user.totpSecret,
      epochTolerance: 1,
    });

    let backupConsumed = false;
    if (!totpResult.valid) {
      const backupCodes = user.mfaBackupCodes ?? [];
      let matchedBackup = false;
      for (const hashed of backupCodes) {
        if (await bcrypt.compare(trimmedCode, hashed)) {
          matchedBackup = true;
          break;
        }
      }
      if (!matchedBackup) {
        throw new UnauthorizedException({
          code: 'INVALID_TOTP_CODE',
          message: 'Invalid code. Please try again.',
        });
      }
      backupConsumed = true;
    }

    await this.prisma.$transaction(async (tx) => {
      await tx.adminTempToken.delete({ where: { id: matched.id } });
      if (backupConsumed) {
        const remaining: string[] = [];
        for (const hashed of user.mfaBackupCodes ?? []) {
          if (!(await bcrypt.compare(trimmedCode, hashed))) {
            remaining.push(hashed);
          }
        }
        await tx.user.update({
          where: { id: user.id },
          data: { mfaBackupCodes: remaining },
        });
      }
    });

    await this.clearAdminLoginFailures(user.email.toLowerCase());
    await this.audit
      .log({
        actorId: user.id,
        action: 'ADMIN_LOGIN_2FA_SUCCESS',
        resourceType: 'User',
        resourceId: user.id,
        metadata: { usedBackupCode: backupConsumed },
      })
      .catch(() => {});

    const freshUser = await this.prisma.user.findUnique({ where: { id: user.id } });
    if (!freshUser) {
      throw new UnauthorizedException({
        code: 'INVALID_TOKEN_USER',
        message: 'User not found',
      });
    }
    return this.sessionService.buildAuthResponse(freshUser, true);
  }

  private async recordAdminLoginFailure(email: string): Promise<void> {
    const now = new Date();
    const existing = await this.prisma.adminLoginFailure.findUnique({ where: { email } });
    if (!existing) {
      await this.prisma.adminLoginFailure.create({
        data: { email, firstFailedAt: now, attemptCount: 1 },
      });
      return;
    }
    const windowMs = LOGIN_LOCKOUT_WINDOW_MINUTES * 60 * 1000;
    const windowStart = now.getTime() - windowMs;
    if (existing.firstFailedAt.getTime() < windowStart) {
      await this.prisma.adminLoginFailure.update({
        where: { email },
        data: { firstFailedAt: now, attemptCount: 1 },
      });
      return;
    }
    await this.prisma.adminLoginFailure.update({
      where: { email },
      data: { attemptCount: { increment: 1 } },
    });
  }

  private async clearAdminLoginFailures(email: string): Promise<void> {
    await this.prisma.adminLoginFailure.deleteMany({ where: { email } }).catch(() => {});
  }
}
