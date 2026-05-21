/// <reference types="jest" />

import { BadRequestException, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createHash } from 'crypto';
import { PasswordResetService } from '../../src/auth/password-reset.service';
import { loadAuthEnvRuntime } from '../../src/auth/auth-env.config';
import { OtpService } from '../../src/otp/otp.service';

describe('PasswordResetService', () => {
  const envWithDevCode = {
    ...loadAuthEnvRuntime(null as unknown as ConfigService),
    shouldReturnDevCode: true,
    saltRounds: 4,
  };

  function makeService(overrides?: {
    prisma?: Record<string, unknown>;
    otp?: Partial<OtpService>;
    email?: { sendAuthTemplate: jest.Mock };
    eligibility?: { isGloballyEnabled: jest.Mock };
  }) {
    const prisma = {
      user: {
        findUnique: jest.fn(),
        update: jest.fn(),
      },
      userDeviceToken: { findMany: jest.fn().mockResolvedValue([]) },
      phoneOtp: { findUnique: jest.fn().mockResolvedValue(null), upsert: jest.fn().mockResolvedValue({}) },
      passwordResetEmailToken: {
        deleteMany: jest.fn().mockResolvedValue({ count: 0 }),
        create: jest.fn().mockResolvedValue({}),
        findFirst: jest.fn(),
        update: jest.fn(),
      },
      userSession: { updateMany: jest.fn().mockResolvedValue({ count: 0 }) },
      loginFailure: { deleteMany: jest.fn().mockResolvedValue({ count: 0 }) },
      $transaction: jest.fn((ops: unknown[]) => Promise.all(ops as Promise<unknown>[])),
      ...overrides?.prisma,
    };

    const otpService = {
      assertOtpMatches: jest.fn().mockResolvedValue(undefined),
      verifyAndConsumeOtp: jest.fn().mockResolvedValue(undefined),
      ...overrides?.otp,
    } as unknown as OtpService;

    const email = overrides?.email ?? {
      sendAuthTemplate: jest.fn().mockResolvedValue(undefined),
    };

    const eligibility = overrides?.eligibility ?? {
      isGloballyEnabled: jest.fn().mockResolvedValue(true),
    };

    const config = {
      get: jest.fn((key: string) => {
        if (key === 'PASSWORD_RESET_URL') return 'https://chisto.mk';
        return undefined;
      }),
    } as unknown as ConfigService;

    const identifierThrottle = { assertAllowed: jest.fn().mockResolvedValue(undefined) };
    const svc = new PasswordResetService(
      prisma as never,
      otpService,
      { sendOtp: jest.fn().mockResolvedValue(undefined) } as never,
      email as never,
      eligibility as never,
      config,
      envWithDevCode,
      identifierThrottle as never,
    );

    return { svc, prisma, otpService, email };
  }

  it('request rejects both phone and email', async () => {
    const { svc } = makeService();
    await expect(
      svc.request({ phoneNumber: '+15551234', email: 'a@b.c' }),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('request returns generic message for unknown phone', async () => {
    const { svc, prisma } = makeService();
    (prisma.user.findUnique as jest.Mock).mockResolvedValue(null);
    const result = await svc.request({ phoneNumber: '+15559999999' });
    expect(result.message).toContain('If an account exists');
    expect(result.devCode).toBeUndefined();
  });

  it('request returns devCode for known phone when env allows', async () => {
    const { svc, prisma } = makeService();
    (prisma.user.findUnique as jest.Mock).mockResolvedValue({ id: 'u1' });
    const result = await svc.request({ phoneNumber: '+15551234567' });
    expect(result.channel).toBe('sms');
    expect(result.devCode).toMatch(/^\d{6}$/);
  });

  it('verifyPasswordResetCode delegates to OtpService', async () => {
    const { svc, otpService } = makeService();
    await svc.verifyPasswordResetCode('+15551234567', '123456');
    expect(otpService.assertOtpMatches).toHaveBeenCalledWith('+15551234567', '123456');
  });

  it('confirmSmsReset applies password and clears login failures', async () => {
    const { svc, prisma } = makeService();
    (prisma.user.findUnique as jest.Mock).mockResolvedValue({
      id: 'u1',
    });
    const result = await svc.confirmSmsReset({
      phoneNumber: '+15551234567',
      code: '123456',
      newPassword: 'NewPass123!',
    });
    expect(result.message).toContain('successful');
    expect(prisma.user.update).toHaveBeenCalled();
    expect(prisma.loginFailure.deleteMany).toHaveBeenCalled();
  });

  it('confirmEmailReset rejects invalid token', async () => {
    const { svc, prisma } = makeService();
    (prisma.passwordResetEmailToken.findFirst as jest.Mock).mockResolvedValue(null);
    await expect(
      svc.confirmEmailReset('bad-token', 'NewPass123!'),
    ).rejects.toBeInstanceOf(UnauthorizedException);
  });

  it('confirmEmailReset succeeds with valid token', async () => {
    const token = 'valid-email-reset-token-16ch';
    const tokenHash = createHash('sha256').update(token).digest('hex');
    const { svc, prisma } = makeService();
    (prisma.passwordResetEmailToken.findFirst as jest.Mock).mockResolvedValue({
      id: 'tok1',
      userId: 'u1',
      user: { phoneNumber: '+15551234567' },
    });

    const result = await svc.confirmEmailReset(token, 'NewPass123!');
    expect(result.message).toContain('successful');
    expect(prisma.passwordResetEmailToken.update).toHaveBeenCalled();
    expect(tokenHash.length).toBeGreaterThan(0);
  });

  it('request email sends template when user exists', async () => {
    const { svc, prisma, email } = makeService();
    (prisma.user.findUnique as jest.Mock).mockResolvedValue({
      id: 'u1',
      email: 'user@test.local',
      firstName: 'Test',
    });
    const result = await svc.request({ email: 'user@test.local' });
    expect(result.channel).toBe('email');
    expect(email.sendAuthTemplate).toHaveBeenCalledWith(
      expect.objectContaining({
        templateId: 'password_reset',
        context: expect.objectContaining({
          resetUrl: expect.stringContaining('reset-password?token='),
        }),
      }),
    );
  });
});
