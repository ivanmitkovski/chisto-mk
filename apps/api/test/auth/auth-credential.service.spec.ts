/// <reference types="jest" />

import { UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import { AuthCredentialService } from '../../src/auth/auth-credential.service';
import { loadAuthEnvRuntime } from '../../src/auth/auth-env.config';
import { AuditService } from '../../src/audit/audit.service';

describe('AuthCredentialService', () => {
  const audit = { log: jest.fn().mockResolvedValue(undefined) } as unknown as AuditService;
  const env = loadAuthEnvRuntime(null as unknown as ConfigService);
  const email = { sendAuthTemplate: jest.fn().mockResolvedValue(undefined) };

  it('changePassword rejects wrong current password', async () => {
    const passwordHash = await bcrypt.hash('CorrectPass1', 4);
    const prisma = {
      user: {
        findUnique: jest.fn().mockResolvedValue({
          passwordHash,
          phoneNumber: '+38970123456',
        }),
        update: jest.fn(),
      },
      loginFailure: { deleteMany: jest.fn().mockResolvedValue({ count: 0 }) },
    } as never;
    const svc = new AuthCredentialService(prisma, audit, email as never, env);
    await expect(
      svc.changePassword('user-1', {
        currentPassword: 'WrongPass1',
        newPassword: 'NewPass123!',
      }),
    ).rejects.toBeInstanceOf(UnauthorizedException);
  });
});
