import { Injectable, Logger, UnauthorizedException } from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import { UserStatus } from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';
import { CitizenLoginDto } from '../dto/citizen-login.dto';
import { AuthResponse } from '../types/auth-response.type';
import { AuthSessionService } from './auth-session.service';
import {
  LOGIN_LOCKOUT_WINDOW_MINUTES,
  LOGIN_MAX_ATTEMPTS,
} from '../constants/auth.constants';
import type { PrismaWithLoginFailure } from '../util/auth-prisma-extensions';
import { maskPhoneNumber } from '../util/auth-phone.util';
import { authLoginFailedTotal, authLoginLockedTotal } from '../../observability/util/prom-registry';

@Injectable()
export class AuthLoginService {
  private readonly logger = new Logger(AuthLoginService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly sessionService: AuthSessionService,
  ) {}

  async citizenLogin(dto: CitizenLoginDto): Promise<AuthResponse> {
    const phoneNumber = dto.phoneNumber.trim();
    const db = this.prisma as PrismaWithLoginFailure;
    const failure = await db.loginFailure.findUnique({
      where: { phoneNumber },
    });
    const now = new Date();
    const windowMs = LOGIN_LOCKOUT_WINDOW_MINUTES * 60 * 1000;
    if (
      failure &&
      failure.attemptCount >= LOGIN_MAX_ATTEMPTS &&
      failure.firstFailedAt.getTime() > now.getTime() - windowMs
    ) {
      const unlockAt = new Date(failure.firstFailedAt.getTime() + windowMs);
      const retryAfterSeconds = Math.max(0, Math.ceil((unlockAt.getTime() - now.getTime()) / 1000));
      authLoginLockedTotal.inc();
      this.logger.warn({
        msg: 'login_locked',
        phoneMasked: maskPhoneNumber(phoneNumber),
        retryAfterSeconds,
      });
      throw new UnauthorizedException({
        code: 'TOO_MANY_ATTEMPTS',
        message: 'Too many failed attempts. Try again later.',
        retryable: true,
        retryAfterSeconds,
      });
    }

    const user = await this.prisma.user.findUnique({
      where: { phoneNumber },
    });

    if (!user) {
      await this.recordLoginFailure(phoneNumber);
      authLoginFailedTotal.inc({ reason: 'invalid_credentials' });
      this.logger.warn({
        msg: 'login_failed',
        reason: 'invalid_credentials',
        phoneMasked: maskPhoneNumber(phoneNumber),
      });
      throw new UnauthorizedException({
        code: 'INVALID_CREDENTIALS',
        message: 'Invalid phone number or password',
      });
    }

    if (user.status !== UserStatus.ACTIVE) {
      throw new UnauthorizedException({
        code: 'ACCOUNT_SUSPENDED',
        message: 'Account is not active',
      });
    }

    const isPasswordValid = await bcrypt.compare(dto.password, user.passwordHash);
    if (!isPasswordValid) {
      await this.recordLoginFailure(phoneNumber);
      authLoginFailedTotal.inc({ reason: 'invalid_credentials' });
      this.logger.warn({
        msg: 'login_failed',
        reason: 'invalid_credentials',
        phoneMasked: maskPhoneNumber(phoneNumber),
        userId: user.id,
      });
      throw new UnauthorizedException({
        code: 'INVALID_CREDENTIALS',
        message: 'Invalid phone number or password',
      });
    }

    if (!user.isPhoneVerified) {
      throw new UnauthorizedException({
        code: 'PHONE_NOT_VERIFIED',
        message: 'Phone number is not verified. Complete verification to sign in.',
        details: { phoneNumberMasked: maskPhoneNumber(phoneNumber) },
      });
    }

    await db.loginFailure.deleteMany({ where: { phoneNumber } }).catch(() => {});

    this.logger.log({
      msg: 'login_success',
      userId: user.id,
      phoneMasked: maskPhoneNumber(phoneNumber),
    });

    return this.sessionService.buildAuthResponse(user, dto.rememberMe ?? true, {
      deviceId: dto.deviceId,
    });
  }

  private async recordLoginFailure(phoneNumber: string): Promise<void> {
    const db = this.prisma as PrismaWithLoginFailure;
    const now = new Date();
    const windowMs = LOGIN_LOCKOUT_WINDOW_MINUTES * 60 * 1000;
    const windowStartMs = now.getTime() - windowMs;

    try {
      const existing = await db.loginFailure.findUnique({ where: { phoneNumber } });
      if (!existing) {
        await db.loginFailure.create({
          data: { phoneNumber, firstFailedAt: now, attemptCount: 1 },
        });
        return;
      }
      if (existing.firstFailedAt.getTime() < windowStartMs) {
        await db.loginFailure.update({
          where: { phoneNumber },
          data: { firstFailedAt: now, attemptCount: 1 },
        });
        return;
      }
      await db.loginFailure.update({
        where: { phoneNumber },
        data: { attemptCount: { increment: 1 } },
      });
    } catch (err: unknown) {
      this.logger.warn(
        `Failed to record login failure for ${maskPhoneNumber(phoneNumber)}: ${String(err)}`,
      );
    }
  }
}
