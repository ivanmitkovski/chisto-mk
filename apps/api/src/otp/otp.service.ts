import { Injectable, UnauthorizedException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

const OTP_MAX_VERIFY_ATTEMPTS = 5;

type PhoneOtpRecord = {
  id: string;
  phoneNumber: string;
  code: string;
  expiresAt: Date;
  attemptCount: number;
};

@Injectable()
export class OtpService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Validates the OTP and deletes the record on success.
   * Throws UnauthorizedException if validation fails.
   */
  async verifyAndConsumeOtp(phoneNumber: string, code: string): Promise<void> {
    const normalized = phoneNumber.trim();
    const record = await this.loadOtpRecordOrThrowNotFound(normalized);
    this.throwIfExpired(normalized, record);
    this.throwIfMaxAttempts(normalized, record);
    await this.throwIfCodeMismatchOrIncrement(normalized, record, code);
    await this.prisma.phoneOtp.delete({ where: { phoneNumber: normalized } });
  }

  /**
   * Validates the OTP against the stored code without consuming it.
   * Used before navigating to "new password" in the password-reset flow;
   * {@link verifyAndConsumeOtp} still runs on {@code confirm} to atomically consume + reset password.
   */
  async assertOtpMatches(phoneNumber: string, code: string): Promise<void> {
    const normalized = phoneNumber.trim();
    const record = await this.loadOtpRecordOrThrowNotFound(normalized);
    this.throwIfExpired(normalized, record);
    this.throwIfMaxAttempts(normalized, record);
    await this.throwIfCodeMismatchOrIncrement(normalized, record, code);
  }

  private async loadOtpRecordOrThrowNotFound(normalized: string): Promise<PhoneOtpRecord> {
    const record = (await this.prisma.phoneOtp.findUnique({
      where: { phoneNumber: normalized },
    })) as PhoneOtpRecord | null;

    if (!record) {
      throw new UnauthorizedException({
        code: 'OTP_NOT_FOUND',
        message: 'Invalid or expired code',
      });
    }
    return record;
  }

  private throwIfExpired(normalized: string, record: PhoneOtpRecord): void {
    if (record.expiresAt < new Date()) {
      void this.prisma.phoneOtp.delete({ where: { phoneNumber: normalized } }).catch(() => {});
      throw new UnauthorizedException({
        code: 'OTP_EXPIRED',
        message: 'Code has expired',
      });
    }
  }

  private throwIfMaxAttempts(normalized: string, record: PhoneOtpRecord): void {
    if (record.attemptCount >= OTP_MAX_VERIFY_ATTEMPTS) {
      void this.prisma.phoneOtp.delete({ where: { phoneNumber: normalized } }).catch(() => {});
      throw new UnauthorizedException({
        code: 'OTP_MAX_ATTEMPTS',
        message: 'Too many attempts',
      });
    }
  }

  private async throwIfCodeMismatchOrIncrement(
    normalized: string,
    record: PhoneOtpRecord,
    code: string,
  ): Promise<void> {
    const expectedCode = String(record.code).trim();
    const providedCode = String(code ?? '').trim();

    if (expectedCode !== providedCode) {
      await this.prisma.phoneOtp.update({
        where: { phoneNumber: normalized },
        data: { attemptCount: record.attemptCount + 1 },
      });
      throw new UnauthorizedException({
        code: 'OTP_INVALID',
        message: 'Invalid code',
      });
    }
  }
}
