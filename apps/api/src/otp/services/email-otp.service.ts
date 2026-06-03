import { Injectable, UnauthorizedException } from '@nestjs/common';
import type { Prisma } from '../../generated/prisma';
import { PrismaService } from '../../prisma/prisma.service';
import { verifyOtpCode } from '../util/otp-code.util';

const OTP_MAX_VERIFY_ATTEMPTS = 5;

type EmailOtpRecord = {
  id: string;
  userId: string;
  codeHash: string;
  expiresAt: Date;
  attemptCount: number;
};

@Injectable()
export class EmailOtpService {
  constructor(private readonly prisma: PrismaService) {}

  async assertMatches(userId: string, code: string): Promise<void> {
    const record = await this.loadRecordOrThrowNotFound(userId);
    this.throwIfExpired(userId, record);
    this.throwIfMaxAttempts(userId, record);
    await this.throwIfCodeMismatchOrIncrement(userId, record, code);
  }

  async verifyAndConsume(
    tx: Prisma.TransactionClient,
    userId: string,
    code: string,
  ): Promise<void> {
    const record = (await tx.passwordResetEmailCode.findUnique({
      where: { userId },
    })) as EmailOtpRecord | null;

    if (!record) {
      throw new UnauthorizedException({
        code: 'OTP_NOT_FOUND',
        message: 'Invalid or expired code',
      });
    }
    this.throwIfExpired(userId, record);
    this.throwIfMaxAttempts(userId, record);
    const ok = await verifyOtpCode(record, code);
    if (!ok) {
      await tx.passwordResetEmailCode.update({
        where: { userId },
        data: { attemptCount: record.attemptCount + 1 },
      });
      throw new UnauthorizedException({
        code: 'OTP_INVALID',
        message: 'Invalid code',
      });
    }
    await tx.passwordResetEmailCode.delete({ where: { userId } });
  }

  private async loadRecordOrThrowNotFound(userId: string): Promise<EmailOtpRecord> {
    const record = (await this.prisma.passwordResetEmailCode.findUnique({
      where: { userId },
    })) as EmailOtpRecord | null;

    if (!record) {
      throw new UnauthorizedException({
        code: 'OTP_NOT_FOUND',
        message: 'Invalid or expired code',
      });
    }
    return record;
  }

  private throwIfExpired(userId: string, record: EmailOtpRecord): void {
    if (record.expiresAt < new Date()) {
      void this.prisma.passwordResetEmailCode
        .delete({ where: { userId } })
        .catch(() => {});
      throw new UnauthorizedException({
        code: 'OTP_EXPIRED',
        message: 'Code has expired',
      });
    }
  }

  private throwIfMaxAttempts(userId: string, record: EmailOtpRecord): void {
    if (record.attemptCount >= OTP_MAX_VERIFY_ATTEMPTS) {
      void this.prisma.passwordResetEmailCode
        .delete({ where: { userId } })
        .catch(() => {});
      throw new UnauthorizedException({
        code: 'OTP_MAX_ATTEMPTS',
        message: 'Too many attempts',
      });
    }
  }

  private async throwIfCodeMismatchOrIncrement(
    userId: string,
    record: EmailOtpRecord,
    code: string,
  ): Promise<void> {
    const ok = await verifyOtpCode(record, code);
    if (!ok) {
      await this.prisma.passwordResetEmailCode.update({
        where: { userId },
        data: { attemptCount: record.attemptCount + 1 },
      });
      throw new UnauthorizedException({
        code: 'OTP_INVALID',
        message: 'Invalid code',
      });
    }
  }
}
