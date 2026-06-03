import { Inject, Injectable, Logger, UnauthorizedException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { OtpService } from '../../otp/services/otp.service';
import { OTP_SENDER, OtpSender, OtpSmsPurpose } from '../../otp/types/otp-sender.interface';
import { ResetPasswordConfirmDto } from '../dto/reset-password-confirm.dto';
import { OTP_EXPIRES_SECONDS } from '../constants/auth.constants';
import { AUTH_ENV_RUNTIME, type AuthEnvRuntime } from '../constants/auth-env.config';
import { generateOtpCode, hashOtpCode } from '../../otp/util/otp-code.util';
import { tryOtpSendAllowed } from '../../otp/util/otp-send-rate.util';
import { maskPhoneForLog } from '../../common/security/mask-pii.util';
import { PasswordResetCompletionService } from './password-reset-completion.service';

@Injectable()
export class PasswordResetSmsFlowService {
  private readonly logger = new Logger(PasswordResetSmsFlowService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly otpService: OtpService,
    @Inject(OTP_SENDER) private readonly otpSender: OtpSender,
    @Inject(AUTH_ENV_RUNTIME) private readonly env: AuthEnvRuntime,
    private readonly completion: PasswordResetCompletionService,
  ) {}

  async sendOtp(phoneNumber: string, acceptLanguage?: string): Promise<string | undefined> {
    const existing = await this.prisma.phoneOtp.findUnique({ where: { phoneNumber } });
    const now = Date.now();
    const sendMeta = tryOtpSendAllowed(existing, now);
    if (!sendMeta) {
      return undefined;
    }

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

    void this.otpSender
      .sendOtp(phoneNumber, code, {
        purpose: OtpSmsPurpose.PasswordReset,
        expiryMinutes,
        ...(acceptLanguage != null && acceptLanguage !== '' ? { localeHint: acceptLanguage } : {}),
      })
      .catch((err: unknown) => {
        this.logger.warn({
          msg: 'password_reset_sms_send_failed',
          phoneMasked: maskPhoneForLog(phoneNumber),
          error: String(err),
        });
      });

    if (this.env.shouldReturnDevCode) {
      return code;
    }
    return undefined;
  }

  async verifyCode(phoneNumber: string, code: string): Promise<void> {
    await this.otpService.assertOtpMatches(phoneNumber.trim(), code);
  }

  async confirmReset(dto: ResetPasswordConfirmDto): Promise<{ message: string }> {
    const normalized = dto.phoneNumber.trim();
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

    await this.completion.applyNewPasswordWithOtpConsume({
      userId: user.id,
      phoneNumber: normalized,
      newPassword: dto.newPassword,
      consumeOtp: (tx) => this.otpService.verifyAndConsume(tx, normalized, dto.code),
    });
    return { message: 'Password reset successful' };
  }
}
