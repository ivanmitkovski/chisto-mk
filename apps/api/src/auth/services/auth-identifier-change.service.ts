import { BadRequestException, Inject, Injectable, OnModuleDestroy } from '@nestjs/common';
import { createHash, randomInt } from 'node:crypto';
import Redis from 'ioredis';
import { optionalLazyRedisOptions } from '../../common/redis/optional-lazy-redis-options';
import { NotificationType } from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';
import { EmailService } from '../../email/services/email.service';
import { AuditService } from '../../audit/services/audit.service';
import { hashPiiForLog } from '../../common/security/pii-hash.util';
import { AuthIdentifierThrottleService } from './auth-identifier-throttle.service';
import { notificationLocalesByUserId } from '../../common/i18n/notification-locale.resolver';
import type { EmailLocale } from '../../email/types/email.types';
import { OTP_SENDER, type OtpSender, OtpSmsPurpose } from '../../otp/types/otp-sender.interface';
import { generateOtpCode } from '../../otp/util/otp-code.util';
import { UserAuthSnapshotCacheService } from './user-auth-snapshot-cache.service';
import { AuthSessionRevocationService } from './auth-session-revocation.service';
import { AUTH_ENV_RUNTIME, type AuthEnvRuntime } from '../constants/auth-env.config';

export type AdminEmailChangeContext = {
  actorId: string;
  reasonCode: string;
  note?: string;
};

export type EmailChangeRequestOptions = {
  adminContext?: AdminEmailChangeContext;
};

export type EmailChangeConfirmResult = {
  initiatedBy: 'admin' | 'user';
  adminContext?: AdminEmailChangeContext;
};

type PendingChange = {
  kind: 'email' | 'phone';
  newValue: string;
  codeHash: string;
  expiresAt: string;
  adminContext?: AdminEmailChangeContext;
};

@Injectable()
export class AuthIdentifierChangeService implements OnModuleDestroy {
  private readonly redis: Redis | null;

  constructor(
    private readonly prisma: PrismaService,
    private readonly email: EmailService,
    private readonly authSnapshotCache: UserAuthSnapshotCacheService,
    private readonly audit: AuditService,
    private readonly identifierThrottle: AuthIdentifierThrottleService,
    private readonly sessionRevocation: AuthSessionRevocationService,
    @Inject(OTP_SENDER) private readonly otpSender: OtpSender,
    @Inject(AUTH_ENV_RUNTIME) private readonly env: AuthEnvRuntime,
  ) {
    const url = process.env.REDIS_URL?.trim();
    this.redis = url ? new Redis(url, optionalLazyRedisOptions) : null;
    if (this.redis) void this.redis.connect().catch(() => undefined);
  }

  async requestEmailChange(
    userId: string,
    newEmail: string,
    options?: EmailChangeRequestOptions,
  ): Promise<{ expiresIn: number; devCode?: string }> {
    const normalized = newEmail.trim().toLowerCase();
    await this.identifierThrottle.assertAllowed('email_change', userId, 3, 3600);
    const taken = await this.prisma.user.findFirst({
      where: { email: normalized, NOT: { id: userId } },
      select: { id: true },
    });
    if (taken) {
      throw new BadRequestException({ code: 'EMAIL_IN_USE', message: 'Email already registered' });
    }
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { id: true, email: true, firstName: true },
    });
    if (!user?.email) {
      throw new BadRequestException({ code: 'USER_NOT_FOUND', message: 'User not found' });
    }
    if (user.email === normalized) {
      throw new BadRequestException({
        code: 'EMAIL_UNCHANGED',
        message: 'New email must differ from the current email',
      });
    }

    const code = String(randomInt(100_000, 999_999));
    const pending: PendingChange = {
      kind: 'email',
      newValue: normalized,
      codeHash: this.hashCode(code),
      expiresAt: new Date(Date.now() + 600_000).toISOString(),
    };
    if (options?.adminContext) {
      pending.adminContext = options.adminContext;
    }
    await this.storePending(userId, pending);

    const locales = await notificationLocalesByUserId(this.prisma, [userId]);
    const rawLocale = locales.get(userId) ?? 'en';
    const locale: EmailLocale = rawLocale === 'mk' ? 'mk' : 'en';
    await this.email.sendAuthTemplate({
      userId,
      to: user.email,
      firstName: user.firstName,
      templateId: 'password_changed',
      locale,
      context: { reason: 'email_change_requested' },
    });
    await this.email.sendTemplate({
      to: normalized,
      userId,
      notificationType: NotificationType.SYSTEM,
      templateId: 'password_reset',
      locale,
      context: {
        firstName: user.firstName,
        resetUrl: `${process.env.EMAIL_APP_BASE_URL ?? 'https://chisto.mk'}/email-confirm?code=${code}`,
      },
      skipPreferenceCheck: true,
    });

    const result: { expiresIn: number; devCode?: string } = { expiresIn: 600 };
    if (this.env.shouldReturnDevCode) {
      result.devCode = code;
    }
    return result;
  }

  async confirmEmailChange(
    userId: string,
    newEmail: string,
    code: string,
  ): Promise<EmailChangeConfirmResult> {
    const normalized = newEmail.trim().toLowerCase();
    const pending = await this.loadPending(userId);
    if (!pending || pending.kind !== 'email' || pending.newValue !== normalized) {
      throw new BadRequestException({ code: 'INVALID_CODE', message: 'Invalid or expired code' });
    }
    if (pending.codeHash !== this.hashCode(code) || new Date(pending.expiresAt) < new Date()) {
      throw new BadRequestException({ code: 'INVALID_CODE', message: 'Invalid or expired code' });
    }

    const before = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { email: true },
    });

    await this.prisma.user.update({
      where: { id: userId },
      data: { email: normalized },
    });

    const adminContext = pending.adminContext;
    const initiatedBy = adminContext ? 'admin' : 'user';
    const actorId = adminContext?.actorId ?? userId;

    await this.clearPending(userId);
    this.authSnapshotCache.invalidate(userId);
    await this.sessionRevocation.revokeAllForUser(userId, 'identifier_changed');
    await this.audit.log({
      actorId,
      action: 'IDENTIFIER_CHANGED',
      resourceType: 'User',
      resourceId: userId,
      metadata: {
        field: 'email',
        initiatedBy,
        reasonCode: adminContext?.reasonCode ?? null,
        oldHash: before?.email ? hashPiiForLog(before.email) : null,
        newHash: hashPiiForLog(normalized),
      },
    });

    const result: EmailChangeConfirmResult = { initiatedBy };
    if (adminContext) {
      result.adminContext = adminContext;
    }
    return result;
  }

  async requestPhoneChange(
    userId: string,
    newPhone: string,
  ): Promise<{ expiresIn: number; devCode?: string }> {
    const normalized = newPhone.trim();
    await this.identifierThrottle.assertAllowed('phone_change', userId, 3, 3600);
    const taken = await this.prisma.user.findFirst({
      where: { phoneNumber: normalized, NOT: { id: userId } },
      select: { id: true },
    });
    if (taken) {
      throw new BadRequestException({ code: 'PHONE_IN_USE', message: 'Phone already registered' });
    }
    const code = generateOtpCode();
    await this.otpSender.sendOtp(normalized, code, {
      purpose: OtpSmsPurpose.PhoneVerification,
      expiryMinutes: 10,
    });
    await this.storePending(userId, {
      kind: 'phone',
      newValue: normalized,
      codeHash: this.hashCode(code),
      expiresAt: new Date(Date.now() + 600_000).toISOString(),
    });
    const result: { expiresIn: number; devCode?: string } = { expiresIn: 600 };
    if (this.env.shouldReturnDevCode) {
      result.devCode = code;
    }
    return result;
  }

  async confirmPhoneChange(userId: string, newPhone: string, code: string): Promise<void> {
    const normalized = newPhone.trim();
    const pending = await this.loadPending(userId);
    if (!pending || pending.kind !== 'phone' || pending.newValue !== normalized) {
      throw new BadRequestException({ code: 'INVALID_CODE', message: 'Invalid or expired code' });
    }
    if (pending.codeHash !== this.hashCode(code) || new Date(pending.expiresAt) < new Date()) {
      throw new BadRequestException({ code: 'INVALID_CODE', message: 'Invalid or expired code' });
    }
    const before = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { phoneNumber: true },
    });
    await this.prisma.user.update({
      where: { id: userId },
      data: { phoneNumber: normalized, isPhoneVerified: true },
    });
    await this.clearPending(userId);
    this.authSnapshotCache.invalidate(userId);
    await this.sessionRevocation.revokeAllForUser(userId, 'identifier_changed');
    await this.audit.log({
      actorId: userId,
      action: 'IDENTIFIER_CHANGED',
      resourceType: 'User',
      resourceId: userId,
      metadata: {
        field: 'phone',
        initiatedBy: 'user',
        oldHash: before?.phoneNumber ? hashPiiForLog(before.phoneNumber) : null,
        newHash: hashPiiForLog(normalized),
      },
    });
  }

  private hashCode(code: string): string {
    return createHash('sha256').update(code).digest('hex');
  }

  private key(userId: string): string {
    return `identifier-change:${userId}`;
  }

  private async storePending(userId: string, value: PendingChange): Promise<void> {
    if (!this.redis) {
      throw new BadRequestException({
        code: 'SERVICE_UNAVAILABLE',
        message: 'Identifier change requires Redis',
      });
    }
    await this.redis.set(this.key(userId), JSON.stringify(value), 'EX', 600);
  }

  private async loadPending(userId: string): Promise<PendingChange | null> {
    if (!this.redis) return null;
    const raw = await this.redis.get(this.key(userId));
    return raw ? (JSON.parse(raw) as PendingChange) : null;
  }

  private async clearPending(userId: string): Promise<void> {
    if (this.redis) await this.redis.del(this.key(userId));
  }

  async onModuleDestroy(): Promise<void> {
    await this.redis?.quit().catch(() => undefined);
  }
}
