/// <reference types="jest" />

import { BadRequestException, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { PasswordResetService } from '../../src/auth/services/password-reset.service';
import { PasswordResetCompletionService } from '../../src/auth/services/password-reset-completion.service';
import { PasswordResetSmsFlowService } from '../../src/auth/services/password-reset-sms-flow.service';
import { PasswordResetEmailFlowService } from '../../src/auth/services/password-reset-email-flow.service';
import { loadAuthEnvRuntime } from '../../src/auth/constants/auth-env.config';
import { OtpService } from '../../src/otp/services/otp.service';
import { EmailOtpService } from '../../src/otp/services/email-otp.service';

describe('PasswordResetService', () => {
  const envWithDevCode = {
    ...loadAuthEnvRuntime(null as unknown as ConfigService),
    shouldReturnDevCode: true,
    saltRounds: 4,
  };

  function makeService(overrides?: {
    prisma?: Record<string, unknown>;
    otp?: Partial<OtpService>;
    emailOtp?: Partial<EmailOtpService>;
    email?: { sendAuthTemplate: jest.Mock };
    eligibility?: { isGloballyEnabled: jest.Mock };
    audit?: { log: jest.Mock };
  }) {
    const prisma = {
      user: {
        findUnique: jest.fn(),
        update: jest.fn(),
      },
      userDeviceToken: { findMany: jest.fn().mockResolvedValue([]) },
      phoneOtp: { findUnique: jest.fn().mockResolvedValue(null), upsert: jest.fn().mockResolvedValue({}) },
      passwordResetEmailCode: {
        findUnique: jest.fn().mockResolvedValue(null),
        upsert: jest.fn().mockResolvedValue({}),
      },
      userSession: { updateMany: jest.fn().mockResolvedValue({ count: 0 }) },
      loginFailure: { deleteMany: jest.fn().mockResolvedValue({ count: 0 }) },
      $transaction: jest.fn(async (fn: (tx: unknown) => Promise<unknown>) => {
        const tx = {
          user: { update: jest.fn() },
          userSession: { updateMany: jest.fn().mockResolvedValue({ count: 0 }) },
          loginFailure: { deleteMany: jest.fn().mockResolvedValue({ count: 0 }) },
          phoneOtp: { delete: jest.fn() },
          passwordResetEmailCode: { delete: jest.fn() },
        };
        return fn(tx);
      }),
      ...overrides?.prisma,
    };

    const otpService = {
      assertOtpMatches: jest.fn().mockResolvedValue(undefined),
      verifyAndConsume: jest.fn().mockResolvedValue(undefined),
      ...overrides?.otp,
    } as unknown as OtpService;

    const emailOtpService = {
      assertMatches: jest.fn().mockResolvedValue(undefined),
      verifyAndConsume: jest.fn().mockResolvedValue(undefined),
      ...overrides?.emailOtp,
    } as unknown as EmailOtpService;

    const email = overrides?.email ?? {
      sendAuthTemplate: jest.fn().mockResolvedValue(undefined),
    };

    const eligibility = overrides?.eligibility ?? {
      isGloballyEnabled: jest.fn().mockResolvedValue(true),
    };

    const audit = overrides?.audit ?? { log: jest.fn().mockResolvedValue(undefined) };

    const identifierThrottle = { assertAllowed: jest.fn().mockResolvedValue(undefined) };
    const completion = new PasswordResetCompletionService(
      prisma as never,
      email as never,
      audit as never,
      envWithDevCode,
    );
    const smsFlow = new PasswordResetSmsFlowService(
      prisma as never,
      otpService,
      { sendOtp: jest.fn().mockResolvedValue(undefined) } as never,
      envWithDevCode,
      completion,
    );
    const emailFlow = new PasswordResetEmailFlowService(
      prisma as never,
      emailOtpService,
      email as never,
      envWithDevCode,
      completion,
    );
    const svc = new PasswordResetService(
      prisma as never,
      eligibility as never,
      identifierThrottle as never,
      smsFlow,
      emailFlow,
    );

    return { svc, prisma, otpService, emailOtpService, email, audit };
  }

  it('request rejects both phone and email', async () => {
    const { svc } = makeService();
    await expect(
      svc.request({ phoneNumber: '+15551234', email: 'a@b.c' }),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('request returns generic message for unknown phone without channel or devCode', async () => {
    const { svc, prisma } = makeService();
    (prisma.user.findUnique as jest.Mock).mockResolvedValue(null);
    const result = await svc.request({ phoneNumber: '+15559999999' });
    expect(result.message).toContain('If an account exists');
    expect(result.devCode).toBeUndefined();
    expect(result).not.toHaveProperty('channel');
  });

  it('request returns devCode for known phone when env allows', async () => {
    const { svc, prisma } = makeService();
    (prisma.user.findUnique as jest.Mock).mockResolvedValue({ id: 'u1' });
    const result = await svc.request({ phoneNumber: '+15551234567' });
    expect(result.devCode).toMatch(/^\d{6}$/);
    expect(result).not.toHaveProperty('channel');
  });

  it('verifyPasswordResetCode delegates to OtpService', async () => {
    const { svc, otpService } = makeService();
    await svc.verifyPasswordResetCode('+15551234567', '123456');
    expect(otpService.assertOtpMatches).toHaveBeenCalledWith('+15551234567', '123456');
  });

  it('verifyPasswordResetCodeByEmail delegates to EmailOtpService', async () => {
    const { svc, prisma, emailOtpService } = makeService();
    (prisma.user.findUnique as jest.Mock).mockResolvedValue({ id: 'u1' });
    await svc.verifyPasswordResetCodeByEmail('user@test.local', '123456');
    expect(emailOtpService.assertMatches).toHaveBeenCalledWith('u1', '123456');
  });

  it('confirmSmsReset applies password inside transaction with audit', async () => {
    const { svc, prisma, otpService, audit } = makeService();
    (prisma.user.findUnique as jest.Mock).mockResolvedValue({ id: 'u1' });
    const result = await svc.confirmSmsReset({
      phoneNumber: '+15551234567',
      code: '123456',
      newPassword: 'NewPass123!',
    });
    expect(result.message).toContain('successful');
    expect(otpService.verifyAndConsume).toHaveBeenCalled();
    expect(audit.log).toHaveBeenCalledWith(
      expect.objectContaining({ action: 'PASSWORD_RESET' }),
    );
  });

  it('confirmEmailReset rejects unknown email', async () => {
    const { svc, prisma } = makeService();
    (prisma.user.findUnique as jest.Mock).mockResolvedValue(null);
    await expect(
      svc.confirmEmailReset('nobody@test.local', '123456', 'NewPass123!'),
    ).rejects.toBeInstanceOf(UnauthorizedException);
  });

  it('confirmEmailReset succeeds with valid code', async () => {
    const { svc, prisma, emailOtpService, audit } = makeService();
    (prisma.user.findUnique as jest.Mock).mockResolvedValue({
      id: 'u1',
      phoneNumber: '+15551234567',
    });

    const result = await svc.confirmEmailReset(
      'user@test.local',
      '123456',
      'NewPass123!',
    );
    expect(result.message).toContain('successful');
    expect(emailOtpService.verifyAndConsume).toHaveBeenCalled();
    expect(audit.log).toHaveBeenCalledWith(
      expect.objectContaining({ action: 'PASSWORD_RESET' }),
    );
  });

  it('request email sends code template when user exists', async () => {
    const { svc, prisma, email } = makeService();
    (prisma.user.findUnique as jest.Mock).mockResolvedValue({
      id: 'u1',
      email: 'user@test.local',
      firstName: 'Test',
    });
    const result = await svc.request({ email: 'user@test.local' });
    expect(result).not.toHaveProperty('channel');
    expect(email.sendAuthTemplate).toHaveBeenCalledWith(
      expect.objectContaining({
        templateId: 'password_reset',
        context: expect.objectContaining({
          code: expect.stringMatching(/^\d{6}$/),
        }),
      }),
    );
  });

  it('request email returns generic response for unknown email', async () => {
    const { svc, prisma, email } = makeService();
    (prisma.user.findUnique as jest.Mock).mockResolvedValue(null);
    const result = await svc.request({ email: 'nobody@test.local' });
    expect(result.message).toContain('If an account exists');
    expect(email.sendAuthTemplate).not.toHaveBeenCalled();
  });
});
