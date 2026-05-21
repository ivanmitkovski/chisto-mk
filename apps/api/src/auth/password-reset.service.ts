import {
  BadRequestException,
  Inject,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createHash, randomBytes } from 'crypto';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../prisma/prisma.service';
import { OtpService } from '../otp/otp.service';
import { OTP_SENDER, OtpSender, OtpSmsPurpose } from '../otp/otp-sender.interface';
import { ResetPasswordConfirmDto } from './dto/reset-password-confirm.dto';
import { OTP_EXPIRES_SECONDS } from './auth.constants';
import { AUTH_ENV_RUNTIME, type AuthEnvRuntime } from './auth-env.config';
import { generateOtpCode, hashOtpCode } from '../otp/otp-code.util';
import { assertOtpSendAllowed } from '../otp/otp-send-rate.util';
import type { PrismaWithLoginFailure } from './auth-prisma-extensions';
import { EmailService } from '../email/email.service';
import { notificationLocalesByUserId } from '../common/i18n/notification-locale.resolver';
import { EmailSendEligibilityService } from '../email/email-send-eligibility.service';
import { AuthIdentifierThrottleService } from './auth-identifier-throttle.service';

const EMAIL_RESET_TOKEN_TTL_MS = 30 * 60 * 1000;

export type PasswordResetRequestResult = {
  message: string;
  channel?: 'sms' | 'email';
  expiresIn?: number;
  devCode?: string;
};

@Injectable()
export class PasswordResetService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly otpService: OtpService,
    @Inject(OTP_SENDER) private readonly otpSender: OtpSender,
    private readonly emailService: EmailService,
    private readonly emailEligibility: EmailSendEligibilityService,
    private readonly config: ConfigService,
    @Inject(AUTH_ENV_RUNTIME) private readonly env: AuthEnvRuntime,
    private readonly identifierThrottle: AuthIdentifierThrottleService,
  ) {}

  async request(params: {
    phoneNumber?: string;
    email?: string;
    acceptLanguage?: string;
  }): Promise<PasswordResetRequestResult> {
    const phone = params.phoneNumber?.trim();
    const email = params.email?.toLowerCase().trim();

    if ((!phone && !email) || (phone && email)) {
      throw new BadRequestException({
        code: 'VALIDATION_ERROR',
        message: 'Provide exactly one of phoneNumber or email',
      });
    }

    const generic: PasswordResetRequestResult = {
      message: 'If an account exists, instructions were sent.',
    };

    if (phone) {
      await this.identifierThrottle.assertAllowed('password_reset', phone, 5, 3600);
      const user = await this.prisma.user.findUnique({
        where: { phoneNumber: phone },
        select: { id: true },
      });
      if (!user) {
        return generic;
      }
      const sent = await this.sendSmsOtp(phone, params.acceptLanguage);
      return {
        ...generic,
        channel: 'sms',
        expiresIn: sent.expiresIn,
        ...(sent.devCode != null ? { devCode: sent.devCode } : {}),
      };
    }

    await this.identifierThrottle.assertAllowed('password_reset', email!, 5, 3600);
    const user = await this.prisma.user.findUnique({
      where: { email: email! },
      select: { id: true, email: true, firstName: true },
    });
    if (!user) {
      return generic;
    }

    if (!(await this.emailEligibility.isGloballyEnabled())) {
      return generic;
    }

    await this.sendEmailResetLink(user.id, user.email, user.firstName);
    return { ...generic, channel: 'email' };
  }

  async verifyPasswordResetCode(phoneNumber: string, code: string): Promise<void> {
    const normalized = phoneNumber.trim();
    await this.otpService.assertOtpMatches(normalized, code);
  }

  async confirmSmsReset(dto: ResetPasswordConfirmDto): Promise<{ message: string }> {
    const normalized = dto.phoneNumber.trim();
    await this.otpService.verifyAndConsumeOtp(normalized, dto.code);

    const user = await this.prisma.user.findUnique({
      where: { phoneNumber: normalized },
      select: { id: true },
    });
    if (!user) {
      throw new UnauthorizedException({
        code: 'USER_NOT_FOUND',
        message: 'User not found for this phone number',
      });
    }

    await this.applyNewPassword(user.id, normalized, dto.newPassword);
    return { message: 'Password reset successful' };
  }

  async confirmEmailReset(token: string, newPassword: string): Promise<{ message: string }> {
    const trimmed = token.trim();
    if (!trimmed) {
      throw new UnauthorizedException({
        code: 'PASSWORD_RESET_TOKEN_INVALID',
        message: 'Invalid or expired reset link',
      });
    }

    const tokenHash = createHash('sha256').update(trimmed).digest('hex');
    const record = await this.prisma.passwordResetEmailToken.findFirst({
      where: {
        tokenHash,
        usedAt: null,
        expiresAt: { gt: new Date() },
      },
      include: { user: { select: { id: true, phoneNumber: true } } },
    });

    if (!record) {
      throw new UnauthorizedException({
        code: 'PASSWORD_RESET_TOKEN_INVALID',
        message: 'Invalid or expired reset link',
      });
    }

    const now = new Date();
    await this.prisma.passwordResetEmailToken.update({
      where: { id: record.id },
      data: { usedAt: now },
    });
    await this.applyNewPassword(record.userId, record.user.phoneNumber, newPassword);

    return { message: 'Password reset successful' };
  }

  private async sendSmsOtp(
    phoneNumber: string,
    acceptLanguage?: string,
  ): Promise<{ expiresIn: number; devCode?: string }> {
    const existing = await this.prisma.phoneOtp.findUnique({ where: { phoneNumber } });
    const now = Date.now();
    const sendMeta = assertOtpSendAllowed(existing, now);
    const code = generateOtpCode();
    const codeHash = await hashOtpCode(code);
    const expiresAt = new Date(now + OTP_EXPIRES_SECONDS * 1000);
    const expiryMinutes = Math.max(1, Math.ceil(OTP_EXPIRES_SECONDS / 60));
    const lastSentAt = new Date(now);

    await this.prisma.phoneOtp.upsert({
      where: { phoneNumber },
      create: {
        phoneNumber,
        code: '',
        codeHash,
        expiresAt,
        lastSentAt,
        sendCountInWindow: sendMeta.sendCountInWindow,
        sendWindowStartedAt: sendMeta.sendWindowStartedAt,
      },
      update: {
        code: '',
        codeHash,
        expiresAt,
        attemptCount: 0,
        lastSentAt,
        sendCountInWindow: sendMeta.sendCountInWindow,
        sendWindowStartedAt: sendMeta.sendWindowStartedAt,
      },
    });
    await this.otpSender.sendOtp(phoneNumber, code, {
      purpose: OtpSmsPurpose.PasswordReset,
      expiryMinutes,
      ...(acceptLanguage != null && acceptLanguage !== '' ? { localeHint: acceptLanguage } : {}),
    });

    const payload: { expiresIn: number; devCode?: string } = {
      expiresIn: OTP_EXPIRES_SECONDS,
    };
    if (this.env.shouldReturnDevCode) {
      payload.devCode = code;
    }
    return payload;
  }

  private async sendEmailResetLink(userId: string, to: string, firstName: string): Promise<void> {
    const token = randomBytes(32).toString('base64url');
    const tokenHash = createHash('sha256').update(token).digest('hex');
    const expiresAt = new Date(Date.now() + EMAIL_RESET_TOKEN_TTL_MS);

    await this.prisma.passwordResetEmailToken.deleteMany({ where: { userId, usedAt: null } });
    await this.prisma.passwordResetEmailToken.create({
      data: { userId, tokenHash, expiresAt },
    });

    const base =
      this.config.get<string>('PASSWORD_RESET_URL')?.trim() ||
      this.config.get<string>('EMAIL_APP_BASE_URL')?.trim() ||
      'https://chisto.mk';
    const resetUrl = `${base.replace(/\/+$/, '')}/reset-password?token=${encodeURIComponent(token)}`;

    const localeBy = await notificationLocalesByUserId(this.prisma, [userId]);
    const locale = localeBy.get(userId) === 'en' ? 'en' : 'mk';

    await this.emailService.sendAuthTemplate({
      userId,
      to,
      firstName,
      templateId: 'password_reset',
      locale,
      context: { resetUrl },
    });
  }

  private async applyNewPassword(
    userId: string,
    phoneNumber: string,
    newPassword: string,
  ): Promise<void> {
    const passwordHash = await bcrypt.hash(newPassword, this.env.saltRounds);
    const now = new Date();
    const db = this.prisma as PrismaWithLoginFailure;
    await this.prisma.$transaction([
      this.prisma.user.update({
        where: { id: userId },
        data: { passwordHash },
      }),
      this.prisma.userSession.updateMany({
        where: { userId, revokedAt: null },
        data: { revokedAt: now },
      }),
      db.loginFailure.deleteMany({ where: { phoneNumber } }),
    ]);
    void this.sendPasswordChangedEmail(userId).catch(() => {});
  }

  private async sendPasswordChangedEmail(userId: string): Promise<void> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { email: true, firstName: true },
    });
    if (!user) return;
    const localeBy = await notificationLocalesByUserId(this.prisma, [userId]);
    const locale = localeBy.get(userId) === 'en' ? 'en' : 'mk';
    await this.emailService.sendAuthTemplate({
      userId,
      to: user.email,
      firstName: user.firstName,
      templateId: 'password_changed',
      locale,
    });
  }
}
