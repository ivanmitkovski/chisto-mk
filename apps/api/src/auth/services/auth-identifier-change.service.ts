import { BadRequestException, Inject, Injectable } from '@nestjs/common';
import { createHash, randomInt } from 'node:crypto';
import Redis from 'ioredis';
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
import { AUTH_ENV_RUNTIME, type AuthEnvRuntime } from '../constants/auth-env.config';

type PendingChange = {
  kind: 'email' | 'phone';
  newValue: string;
  codeHash: string;
  expiresAt: string;
};

@Injectable()
export class AuthIdentifierChangeService {
  private readonly redis: Redis | null;

  constructor(
    private readonly prisma: PrismaService,
    private readonly email: EmailService,
    private readonly authSnapshotCache: UserAuthSnapshotCacheService,
    private readonly audit: AuditService,
    private readonly identifierThrottle: AuthIdentifierThrottleService,
    @Inject(OTP_SENDER) private readonly otpSender: OtpSender,
    @Inject(AUTH_ENV_RUNTIME) private readonly env: AuthEnvRuntime,
  ) {
    const url = process.env.REDIS_URL?.trim();
    this.redis = url ? new Redis(url, { maxRetriesPerRequest: 1, lazyConnect: true }) : null;
    if (this.redis) void this.redis.connect().catch(() => undefined);
  }

  async requestEmailChange(
    userId: string,
    newEmail: string,
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

    const code = String(randomInt(100_000, 999_999));
    await this.storePending(userId, {
      kind: 'email',
      newValue: normalized,
      codeHash: this.hashCode(code),
      expiresAt: new Date(Date.now() + 600_000).toISOString(),
    });

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

  async confirmEmailChange(userId: string, newEmail: string, code: string): Promise<void> {
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

    await this.clearPending(userId);
    this.authSnapshotCache.invalidate(userId);
    await this.audit.log({
      actorId: userId,
      action: 'IDENTIFIER_CHANGED',
      resourceType: 'User',
      resourceId: userId,
      metadata: {
        field: 'email',
        oldHash: before?.email ? hashPiiForLog(before.email) : null,
        newHash: hashPiiForLog(normalized),
      },
    });
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
    await this.audit.log({
      actorId: userId,
      action: 'IDENTIFIER_CHANGED',
      resourceType: 'User',
      resourceId: userId,
      metadata: {
        field: 'phone',
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
}
