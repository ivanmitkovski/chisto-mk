import { BadRequestException, Inject, Injectable, Logger } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { NotificationType } from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';
import { OTP_SENDER, OtpSender, OtpSmsPurpose } from '../../otp/types/otp-sender.interface';
import { OtpService } from '../../otp/services/otp.service';
import { AuditService } from '../../audit/services/audit.service';
import { OTP_EXPIRES_SECONDS } from '../constants/auth.constants';
import { AUTH_ENV_RUNTIME, type AuthEnvRuntime } from '../constants/auth-env.config';
import { generateOtpCode, hashOtpCode } from '../../otp/util/otp-code.util';
import { assertOtpSendAllowed } from '../../otp/util/otp-send-rate.util';
import { AuthSessionService } from './auth-session.service';
import { AuthResponse } from '../types/auth-response.type';
import { EmailService } from '../../email/services/email.service';
import type { EmailLocale } from '../../email/types/email.types';
import { notificationLocalesByUserId } from '../../common/i18n/notification-locale.resolver';
import type { AppLocale } from '../../common/i18n/app-locale';
import { welcomePushCopy } from '../../notifications/util/notification-templates';
import { AuthIdentifierThrottleService } from './auth-identifier-throttle.service';

@Injectable()
export class AuthOtpService {
  private readonly logger = new Logger(AuthOtpService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly otpService: OtpService,
    @Inject(OTP_SENDER) private readonly otpSender: OtpSender,
    private readonly sessionService: AuthSessionService,
    private readonly audit: AuditService,
    private readonly emailService: EmailService,
    @Inject(AUTH_ENV_RUNTIME) private readonly env: AuthEnvRuntime,
    private readonly identifierThrottle: AuthIdentifierThrottleService,
    private readonly eventEmitter: EventEmitter2,
  ) {}

  async sendPhoneVerificationOtp(
    phoneNumber: string,
    acceptLanguage?: string,
  ): Promise<{ expiresIn: number; devCode?: string }> {
    return this.sendOtp(phoneNumber, OtpSmsPurpose.PhoneVerification, acceptLanguage);
  }

  async sendOtp(
    phoneNumber: string,
    purpose: OtpSmsPurpose,
    acceptLanguage?: string,
  ): Promise<{ expiresIn: number; devCode?: string }> {
    const normalized = phoneNumber.trim();
    const user = await this.prisma.user.findUnique({
      where: { phoneNumber: normalized },
      select: { id: true },
    });
    if (!user) {
      throw new BadRequestException({
        code: 'OTP_SEND_FAILED',
        message: 'If this phone number is registered, a verification code will be sent',
      });
    }

    await this.identifierThrottle.assertAllowed('otp_send', normalized, 5, 3600);

    const existing = await this.prisma.phoneOtp.findUnique({
      where: { phoneNumber: normalized },
    });
    const now = Date.now();
    const sendMeta = assertOtpSendAllowed(existing, now);

    const code = generateOtpCode();
    const codeHash = await hashOtpCode(code);
    const expiresAt = new Date(now + OTP_EXPIRES_SECONDS * 1000);
    const expiryMinutes = Math.max(1, Math.ceil(OTP_EXPIRES_SECONDS / 60));
    const lastSentAt = new Date(now);

    await this.prisma.phoneOtp.upsert({
      where: { phoneNumber: normalized },
      create: {
        phoneNumber: normalized,
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
    try {
      await this.otpSender.sendOtp(normalized, code, {
        purpose,
        expiryMinutes,
        ...(acceptLanguage != null && acceptLanguage !== '' ? { localeHint: acceptLanguage } : {}),
      });
    } catch (err: unknown) {
      this.logger.warn({
        msg: 'otp_send_failed',
        phoneMasked: normalized.replace(/\d(?=\d{2})/g, '*'),
        purpose,
        error: String(err),
      });
      throw new BadRequestException({
        code: 'OTP_SEND_FAILED',
        message: 'Unable to send verification code. Please try again later.',
      });
    }

    const payload: { expiresIn: number; devCode?: string } = {
      expiresIn: OTP_EXPIRES_SECONDS,
    };
    if (this.env.shouldReturnDevCode) {
      payload.devCode = code;
    }
    return payload;
  }

  async verifyPhoneAndIssueSession(
    phoneNumber: string,
    code: string,
    rememberMe = true,
    deviceId?: string,
    ipAddress?: string | null,
  ): Promise<AuthResponse> {
    const normalized = phoneNumber.trim();
    await this.otpService.verifyAndConsumeOtp(normalized, code);

    const beforeVerify = await this.prisma.user.findUnique({
      where: { phoneNumber: normalized },
      select: { id: true, isPhoneVerified: true },
    });
    if (beforeVerify == null) {
      throw new BadRequestException({
        code: 'USER_NOT_FOUND',
        message: 'User not found for this phone number',
      });
    }
    const isFirstVerification = !beforeVerify.isPhoneVerified;

    const user = await this.prisma.user.update({
      where: { phoneNumber: normalized },
      data: { isPhoneVerified: true },
    });

    await this.audit.log({
      actorId: user.id,
      action: 'PHONE_VERIFIED',
      resourceType: 'User',
      resourceId: user.id,
    });

    const localeBy = await notificationLocalesByUserId(this.prisma, [user.id]);
    const locale = localeBy.get(user.id)!;
    if (isFirstVerification) {
      void this.emitWelcomePushIfNew(user.id, locale).catch((err: unknown) => {
        this.logger.warn({
          msg: 'welcome_push_send_failed',
          userId: user.id,
          error: String(err),
        });
      });
    }
    const emailLocale: EmailLocale = locale === 'en' ? 'en' : 'mk';
    void this.emailService
      .sendAuthTemplate({
        userId: user.id,
        to: user.email,
        firstName: user.firstName,
        templateId: 'welcome',
        locale: emailLocale,
      })
      .catch((err: unknown) => {
        this.logger.warn({
          msg: 'welcome_email_send_failed',
          userId: user.id,
          error: String(err),
        });
      });

    return this.sessionService.buildAuthResponse(user, rememberMe, {
      deviceId,
      ipAddress: ipAddress ?? null,
    });
  }

  private async emitWelcomePushIfNew(
    userId: string,
    locale: AppLocale,
  ): Promise<void> {
    const existing = await this.prisma.userNotification.findFirst({
      where: { userId, type: NotificationType.WELCOME },
      select: { id: true },
    });
    if (existing != null) {
      return;
    }
    const { title, body } = welcomePushCopy(locale);
    this.eventEmitter.emit('notification.send', {
      recipientUserIds: [userId],
      title,
      body,
      type: NotificationType.WELCOME,
      threadKey: `welcome:${userId}`,
      groupKey: 'WELCOME',
      data: { kind: 'welcome' },
    });
  }
}
