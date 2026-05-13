/// <reference types="jest" />
jest.mock('otplib', () => ({
  generateSecret: jest.fn(() => 'test-secret'),
  generateURI: jest.fn(() => 'otpauth://totp/test'),
  verify: jest.fn(() => ({ valid: true })),
}));

import { BadRequestException, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AuthMfaService } from '../../src/auth/auth-mfa.service';
import { loadAuthEnvRuntime } from '../../src/auth/auth-env.config';
import { AuditService } from '../../src/audit/audit.service';

describe('AuthMfaService', () => {
  const audit = { log: jest.fn().mockResolvedValue(undefined) } as unknown as AuditService;
  const env = loadAuthEnvRuntime(null as unknown as ConfigService);

  it('setupMfa throws when user is missing', async () => {
    const prisma = {
      user: { findUnique: jest.fn().mockResolvedValue(null) },
    } as never;
    const svc = new AuthMfaService(prisma, audit, env);
    await expect(svc.setupMfa('missing')).rejects.toBeInstanceOf(UnauthorizedException);
  });

  it('setupMfa throws when MFA is already enabled', async () => {
    const prisma = {
      user: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'u1',
          email: 'a@b.c',
          totpSecret: 'already',
        }),
      },
    } as never;
    const svc = new AuthMfaService(prisma, audit, env);
    await expect(svc.setupMfa('u1')).rejects.toBeInstanceOf(BadRequestException);
  });
});
