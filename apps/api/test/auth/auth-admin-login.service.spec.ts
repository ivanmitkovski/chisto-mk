/// <reference types="jest" />
jest.mock('otplib', () => ({
  generateSecret: jest.fn(() => 'test-secret'),
  generateURI: jest.fn(() => 'otpauth://totp/test'),
  verify: jest.fn(() => ({ valid: true })),
}));

import { UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AuthAdminLoginService } from '../../src/auth/auth-admin-login.service';
import { loadAuthEnvRuntime } from '../../src/auth/auth-env.config';
import { AuthSessionService } from '../../src/auth/auth-session.service';
import { AuditService } from '../../src/audit/audit.service';
import { LOGIN_MAX_ATTEMPTS } from '../../src/auth/auth.constants';

describe('AuthAdminLoginService', () => {
  const audit = { log: jest.fn().mockResolvedValue(undefined) } as unknown as AuditService;
  const env = loadAuthEnvRuntime(null as unknown as ConfigService);
  const sessionService = {} as AuthSessionService;

  it('returns TOO_MANY_ATTEMPTS when lockout window is active', async () => {
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
});
