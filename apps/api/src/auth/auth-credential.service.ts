import {
  BadRequestException,
  Inject,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import { PrismaService } from '../prisma/prisma.service';
import { ChangePasswordDto } from './dto/change-password.dto';
import { ResetPasswordConfirmDto } from './dto/reset-password-confirm.dto';
import { OTP_SENDER, OtpSender, OtpSmsPurpose } from '../otp/otp-sender.interface';
import { OtpService } from '../otp/otp.service';
import { AuditService } from '../audit/audit.service';
import { OTP_EXPIRES_SECONDS } from './auth.constants';
import type { PrismaWithLoginFailure } from './auth-prisma-extensions';
import { AUTH_ENV_RUNTIME, type AuthEnvRuntime } from './auth-env.config';

@Injectable()
export class AuthCredentialService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly otpService: OtpService,
    @Inject(OTP_SENDER) private readonly otpSender: OtpSender,
    private readonly audit: AuditService,
    @Inject(AUTH_ENV_RUNTIME) private readonly env: AuthEnvRuntime,
  ) {}

  async sendOtp(
    phoneNumber: string,
    options: { purpose: OtpSmsPurpose; acceptLanguage?: string },
  ): Promise<{ expiresIn: number; devCode?: string }> {
    const normalized = phoneNumber.trim();
    const user = await this.prisma.user.findUnique({
      where: { phoneNumber: normalized },
      select: { id: true },
    });
    if (!user) {
      throw new BadRequestException({
        code: 'PHONE_NOT_REGISTERED',
        message: 'No account found for this phone number',
      });
    }

    const code = String(Math.floor(1000 + Math.random() * 9000));
    const expiresAt = new Date(Date.now() + OTP_EXPIRES_SECONDS * 1000);
    const expiryMinutes = Math.max(1, Math.ceil(OTP_EXPIRES_SECONDS / 60));

    await this.prisma.phoneOtp.upsert({
      where: { phoneNumber: normalized },
      create: { phoneNumber: normalized, code, expiresAt },
      update: { code, expiresAt, attemptCount: 0 } as Record<string, unknown>,
    });
    await this.otpSender.sendOtp(normalized, code, {
      purpose: options.purpose,
      expiryMinutes,
      ...(options.acceptLanguage != null && options.acceptLanguage !== ''
        ? { localeHint: options.acceptLanguage }
        : {}),
    });
    const payload: { expiresIn: number; devCode?: string } = {
      expiresIn: OTP_EXPIRES_SECONDS,
    };
    if (this.env.shouldReturnDevCode) {
      payload.devCode = code;
    }
    return payload;
  }

  async verifyOtp(phoneNumber: string, code: string): Promise<void> {
    const normalized = phoneNumber.trim();
    await this.otpService.verifyAndConsumeOtp(normalized, code);
    await this.prisma.user.update({
      where: { phoneNumber: normalized },
      data: { isPhoneVerified: true },
    });
  }

  /** Checks the password-reset OTP without consuming it (see {@link confirmPasswordReset}). */
  async verifyPasswordResetCode(phoneNumber: string, code: string): Promise<void> {
    const normalized = phoneNumber.trim();
    await this.otpService.assertOtpMatches(normalized, code);
  }

  async confirmPasswordReset(dto: ResetPasswordConfirmDto): Promise<{ message: string }> {
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

    const passwordHash = await bcrypt.hash(dto.newPassword, this.env.saltRounds);
    const now = new Date();

    const db = this.prisma as PrismaWithLoginFailure;
    await this.prisma.$transaction([
      this.prisma.user.update({
        where: { phoneNumber: normalized },
        data: { passwordHash },
      }),
      this.prisma.userSession.updateMany({
        where: { userId: user.id, revokedAt: null },
        data: { revokedAt: now },
      }),
      db.loginFailure.deleteMany({ where: { phoneNumber: normalized } }),
    ]);

    return { message: 'Password reset successful' };
  }

  async changePassword(userId: string, dto: ChangePasswordDto): Promise<void> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { passwordHash: true, phoneNumber: true },
    });
    if (!user) {
      throw new UnauthorizedException({
        code: 'INVALID_TOKEN_USER',
        message: 'User not found',
      });
    }
    const currentValid = await bcrypt.compare(dto.currentPassword, user.passwordHash);
    if (!currentValid) {
      throw new UnauthorizedException({
        code: 'CURRENT_PASSWORD_INVALID',
        message: 'Current password is incorrect',
      });
    }
    const passwordHash = await bcrypt.hash(dto.newPassword, this.env.saltRounds);
    await this.prisma.user.update({
      where: { id: userId },
      data: { passwordHash },
    });
    const db = this.prisma as PrismaWithLoginFailure;
    await db.loginFailure.deleteMany({ where: { phoneNumber: user.phoneNumber } }).catch(() => {});
    await this.audit.log({
      actorId: userId,
      action: 'PASSWORD_CHANGED',
      resourceType: 'User',
      resourceId: userId,
    });
  }
}
