import { Inject, Injectable, Logger, UnauthorizedException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { EmailOtpService } from '../../otp/services/email-otp.service';
import { OTP_EXPIRES_SECONDS } from '../constants/auth.constants';
import { AUTH_ENV_RUNTIME, type AuthEnvRuntime } from '../constants/auth-env.config';
import { generateOtpCode, hashOtpCode } from '../../otp/util/otp-code.util';
import { tryOtpSendAllowed } from '../../otp/util/otp-send-rate.util';
import { EmailService } from '../../email/services/email.service';
import { notificationLocalesByUserId } from '../../common/i18n/notification-locale.resolver';
import { maskEmailForLog } from '../../common/security/mask-pii.util';
import { PasswordResetCompletionService } from './password-reset-completion.service';

@Injectable()
export class PasswordResetEmailFlowService {
  private readonly logger = new Logger(PasswordResetEmailFlowService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly emailOtpService: EmailOtpService,
    private readonly emailService: EmailService,
    @Inject(AUTH_ENV_RUNTIME) private readonly env: AuthEnvRuntime,
    private readonly completion: PasswordResetCompletionService,
  ) {}

  async sendCode(userId: string, to: string, firstName: string): Promise<string | undefined> {
    const existing = await this.prisma.passwordResetEmailCode.findUnique({
      where: { userId },
    });
    const now = Date.now();
    const sendMeta = tryOtpSendAllowed(existing, now);
    if (!sendMeta) {
      return undefined;
    }

    const code = generateOtpCode();
    const codeHash = await hashOtpCode(code);
    const expiresAt = new Date(now + OTP_EXPIRES_SECONDS * 1000);
    const lastSentAt = new Date(now);

    await this.prisma.passwordResetEmailCode.upsert({
      where: { userId },
      create: {
        userId,
        codeHash,
        expiresAt,
        lastSentAt,
        sendCountInWindow: sendMeta.sendCountInWindow,
        sendWindowStartedAt: sendMeta.sendWindowStartedAt,
      },
      update: {
        codeHash,
        expiresAt,
        attemptCount: 0,
        lastSentAt,
        sendCountInWindow: sendMeta.sendCountInWindow,
        sendWindowStartedAt: sendMeta.sendWindowStartedAt,
      },
    });

    const localeBy = await notificationLocalesByUserId(this.prisma, [userId]);
    const locale = localeBy.get(userId) === 'en' ? 'en' : 'mk';

    void this.emailService
      .sendAuthTemplate({
        userId,
        to,
        firstName,
        templateId: 'password_reset',
        locale,
        context: { code },
      })
      .catch((err: unknown) => {
        this.logger.warn({
          msg: 'password_reset_email_send_failed',
          emailMasked: maskEmailForLog(to),
          userId,
          error: String(err),
        });
      });

    if (this.env.shouldReturnDevCode) {
      return code;
    }
    return undefined;
  }

  async verifyCode(email: string, code: string): Promise<void> {
    const normalizedEmail = email.toLowerCase().trim();
    const user = await this.prisma.user.findUnique({
      where: { email: normalizedEmail },
      select: { id: true },
    });
    if (!user) {
      throw new UnauthorizedException({
        code: 'OTP_NOT_FOUND',
        message: 'Invalid or expired code',
      });
    }
    await this.emailOtpService.assertMatches(user.id, code);
  }

  async confirmReset(
    email: string,
    code: string,
    newPassword: string,
  ): Promise<{ message: string }> {
    const normalizedEmail = email.toLowerCase().trim();
    const user = await this.prisma.user.findUnique({
      where: { email: normalizedEmail },
      select: { id: true, phoneNumber: true },
    });
    if (!user) {
      throw new UnauthorizedException({
        code: 'OTP_NOT_FOUND',
        message: 'Invalid or expired code',
      });
    }

    await this.completion.applyNewPasswordWithOtpConsume({
      userId: user.id,
      phoneNumber: user.phoneNumber,
      newPassword,
      consumeOtp: (tx) => this.emailOtpService.verifyAndConsume(tx, user.id, code),
    });
    return { message: 'Password reset successful' };
  }
}
