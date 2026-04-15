import { HttpException, HttpStatus, Injectable, NotFoundException } from '@nestjs/common';
import { Prisma } from '../prisma-client';
import { PrismaService } from '../prisma/prisma.service';
import { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { ReportCapacityDto } from './dto/report-capacity.dto';

const INITIAL_REPORT_CREDITS = 10;
const DEFAULT_EMERGENCY_WINDOW_DAYS = 7;

@Injectable()
export class ReportCapacityService {
  constructor(private readonly prisma: PrismaService) {}

  async getCapacityForCurrentUser(user: AuthenticatedUser): Promise<ReportCapacityDto> {
    const current = await this.prisma.user.findUnique({
      where: { id: user.userId },
      select: {
        reportCreditsAvailable: true,
        reportEmergencyWindowDays: true,
        reportEmergencyUsedAt: true,
      },
    });

    if (!current) {
      throw new NotFoundException({
        code: 'USER_NOT_FOUND',
        message: `User with id '${user.userId}' was not found`,
      });
    }

    return this.buildCapacityDto(current, new Date());
  }

  /**
   * Debits one report credit or emergency slot inside an existing transaction.
   */
  async spendWithinTransaction(
    tx: Pick<Prisma.TransactionClient, 'user'>,
    userId: string,
    now: Date,
  ): Promise<void> {
    const spentFromCredits = await tx.user.updateMany({
      where: {
        id: userId,
        reportCreditsAvailable: { gt: 0 },
      },
      data: {
        reportCreditsAvailable: { decrement: 1 },
        reportCreditsSpentTotal: { increment: 1 },
      },
    });

    if (spentFromCredits.count > 0) {
      return;
    }

    const row = await tx.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        reportCreditsAvailable: true,
        reportEmergencyWindowDays: true,
        reportEmergencyUsedAt: true,
      },
    });

    if (!row) {
      throw new NotFoundException({
        code: 'USER_NOT_FOUND',
        message: `User with id '${userId}' was not found`,
      });
    }

    const windowDays = row.reportEmergencyWindowDays || DEFAULT_EMERGENCY_WINDOW_DAYS;
    const emergencyAvailable =
      !row.reportEmergencyUsedAt ||
      row.reportEmergencyUsedAt.getTime() + windowDays * 24 * 60 * 60 * 1000 <= now.getTime();

    if (emergencyAvailable) {
      await tx.user.update({
        where: { id: userId },
        data: {
          reportEmergencyUsedAt: now,
          reportCreditsSpentTotal: { increment: 1 },
        },
      });
      return;
    }

    throw new HttpException(
      {
        code: 'REPORTING_COOLDOWN',
        message:
          'You have used all report credits and emergency allowance. Join or create an eco action to unlock more reports.',
        details: {
          creditsAvailable: row.reportCreditsAvailable,
          emergencyAvailable: false,
          retryAfterSeconds: row.reportEmergencyUsedAt
            ? this.emergencyRetryAfterSeconds(row.reportEmergencyUsedAt, windowDays, now)
            : null,
          unlockHint: 'Join and verify attendance, or create an eco action to unlock 10 new reports.',
        },
      },
      HttpStatus.TOO_MANY_REQUESTS,
    );
  }

  private emergencyRetryAfterSeconds(lastUsedAt: Date, windowDays: number, now: Date): number {
    const windowMs = windowDays * 24 * 60 * 60 * 1000;
    const unlockAtMs = lastUsedAt.getTime() + windowMs;
    return Math.max(1, Math.ceil((unlockAtMs - now.getTime()) / 1000));
  }

  private buildCapacityDto(
    user: {
      reportCreditsAvailable: number;
      reportEmergencyWindowDays: number;
      reportEmergencyUsedAt: Date | null;
    },
    now: Date,
  ): ReportCapacityDto {
    const windowDays = user.reportEmergencyWindowDays || DEFAULT_EMERGENCY_WINDOW_DAYS;
    const creditsAvailable = user.reportCreditsAvailable ?? INITIAL_REPORT_CREDITS;

    let emergencyAvailable = true;
    let retryAfterSeconds: number | null = null;
    let nextEmergencyReportAvailableAt: string | null = null;
    if (user.reportEmergencyUsedAt) {
      const windowMs = windowDays * 24 * 60 * 60 * 1000;
      const unlockAtMs = user.reportEmergencyUsedAt.getTime() + windowMs;
      if (unlockAtMs > now.getTime()) {
        emergencyAvailable = false;
        retryAfterSeconds = this.emergencyRetryAfterSeconds(user.reportEmergencyUsedAt, windowDays, now);
        nextEmergencyReportAvailableAt = new Date(unlockAtMs).toISOString();
      }
    }

    return {
      creditsAvailable,
      emergencyAvailable,
      emergencyWindowDays: windowDays,
      retryAfterSeconds,
      nextEmergencyReportAvailableAt,
      unlockHint: 'Join and verify attendance, or create an eco action to unlock 10 new reports.',
    };
  }
}
