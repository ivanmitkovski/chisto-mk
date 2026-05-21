import { BadRequestException, Inject, Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { OTP_SENDER, OtpSender, OtpSmsPurpose } from '../otp/otp-sender.interface';
import { OtpService } from '../otp/otp.service';
import { AuditService } from '../audit/audit.service';
import { OTP_EXPIRES_SECONDS } from './auth.constants';
import { AUTH_ENV_RUNTIME, type AuthEnvRuntime } from './auth-env.config';
import { generateOtpCode, hashOtpCode } from '../otp/otp-code.util';
import { assertOtpSendAllowed } from '../otp/otp-send-rate.util';
import { AuthSessionService } from './auth-session.service';
import { AuthResponse } from './types/auth-response.type';
import { EmailService } from '../email/email.service';
import { notificationLocalesByUserId } from '../common/i18n/notification-locale.resolver';
import { AuthIdentifierThrottleService } from './auth-identifier-throttle.service';

@Injectable()
export class AuthOtpService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly otpService: OtpService,
    @Inject(OTP_SENDER) private readonly otpSender: OtpSender,
    private readonly sessionService: AuthSessionService,
    private readonly audit: AuditService,
    private readonly emailService: EmailService,
    @Inject(AUTH_ENV_RUNTIME) private readonly env: AuthEnvRuntime,
    private readonly identifierThrottle: AuthIdentifierThrottleService,
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
    await this.otpSender.sendOtp(normalized, code, {
      purpose,
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

  async verifyPhoneAndIssueSession(
    phoneNumber: string,
    code: string,
    rememberMe = true,
  ): Promise<AuthResponse> {
    const normalized = phoneNumber.trim();
    await this.otpService.verifyAndConsumeOtp(normalized, code);

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
    const locale = localeBy.get(user.id) === 'en' ? 'en' : 'mk';
    void this.emailService
      .sendAuthTemplate({
        userId: user.id,
        to: user.email,
        firstName: user.firstName,
        templateId: 'welcome',
        locale,
      })
      .catch(() => {});

    return this.sessionService.buildAuthResponse(user, rememberMe);
  }
}
