/// <reference types="jest" />
jest.mock('otplib', () => ({
  generateSecret: jest.fn(() => 'test-secret'),
  generateURI: jest.fn(() => 'otpauth://totp/test'),
  verify: jest.fn(() => ({ valid: true })),
}));

import { UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Role, UserStatus } from '../../src/prisma-client';
import { AuthAdminLoginService } from '../../src/auth/services/auth-admin-login.service';
import { loadAuthEnvRuntime, REMEMBER_ME_SHORT_DAYS } from '../../src/auth/constants/auth-env.config';
import { AuthSessionService } from '../../src/auth/services/auth-session.service';
import { AuditService } from '../../src/audit/services/audit.service';
import { LOGIN_MAX_ATTEMPTS } from '../../src/auth/constants/auth.constants';

describe('AuthAdminLoginService', () => {
  const audit = { log: jest.fn().mockResolvedValue(undefined) } as unknown as AuditService;
  const env = loadAuthEnvRuntime(null as unknown as ConfigService);

  it('returns TOO_MANY_ATTEMPTS when lockout window is active', async () => {
    const sessionService = {} as AuthSessionService;
    const now = Date.now();
    const prisma = {
      adminLoginFailure: {
        findUnique: jest.fn().mockResolvedValue({
          email: 'a@b.c',
          attemptCount: LOGIN_MAX_ATTEMPTS,
          firstFailedAt: new Date(now - 60_000),
        }),
      },
    } as never;
    const svc = new AuthAdminLoginService(prisma, audit, sessionService, env);
    await expect(svc.adminLogin({ email: 'a@b.c', password: 'x' } as never)).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
  });

  it('returns INVALID_CREDENTIALS when user is missing', async () => {
    const sessionService = {} as AuthSessionService;
    const prisma = {
      adminLoginFailure: {
        findUnique: jest.fn().mockResolvedValue(null),
        create: jest.fn().mockResolvedValue({}),
      },
      user: { findUnique: jest.fn().mockResolvedValue(null) },
    } as never;
    const svc = new AuthAdminLoginService(prisma, audit, sessionService, env);
    await expect(
      svc.adminLogin({ email: 'missing@b.c', password: 'StrongPass123!' }),
    ).rejects.toBeInstanceOf(UnauthorizedException);
    expect((prisma as { adminLoginFailure: { create: jest.Mock } }).adminLoginFailure.create).toHaveBeenCalled();
  });

  it('passes rememberMe=false to session builder for short-lived admin sessions', async () => {
    const buildAuthResponse = jest.fn().mockResolvedValue({
      accessToken: 'access',
      refreshToken: 'refresh',
    });
    const sessionService = { buildAuthResponse } as unknown as AuthSessionService;
    const prisma = {
      adminLoginFailure: {
        findUnique: jest.fn().mockResolvedValue(null),
        deleteMany: jest.fn().mockResolvedValue({ count: 0 }),
      },
      user: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'admin-1',
          email: 'admin@chisto.mk',
          passwordHash: '$2b$12$hashed',
          role: Role.ADMIN,
          status: UserStatus.ACTIVE,
          totpSecret: null,
        }),
      },
    } as never;

    jest.spyOn(require('bcrypt'), 'compare').mockResolvedValue(true);

    const svc = new AuthAdminLoginService(prisma, audit, sessionService, env);
    await svc.adminLogin({
      email: 'admin@chisto.mk',
      password: 'StrongPass123!',
      deviceId: 'device-1',
      rememberMe: false,
    });

    expect(buildAuthResponse).toHaveBeenCalledWith(
      expect.objectContaining({ id: 'admin-1' }),
      false,
      { deviceId: 'device-1' },
    );
    expect(REMEMBER_ME_SHORT_DAYS).toBe(1);
  });
});
