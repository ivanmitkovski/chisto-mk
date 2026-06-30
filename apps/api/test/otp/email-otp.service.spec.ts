/// <reference types="jest" />
jest.mock('bcrypt', () => ({
  ...jest.requireActual<typeof import('bcrypt')>('bcrypt'),
  compare: jest.fn(),
}));

import { UnauthorizedException } from '@nestjs/common';
import * as bcrypt from 'bcrypt';
import { EmailOtpService } from '../../src/otp/services/email-otp.service';

describe('EmailOtpService', () => {
  function makeService(overrides?: { prisma?: Record<string, unknown> }) {
    const prisma = {
      passwordResetEmailCode: {
        findUnique: jest.fn(),
        update: jest.fn(),
        delete: jest.fn(),
      },
      ...overrides?.prisma,
    };
    return {
      svc: new EmailOtpService(prisma as never),
      prisma,
    };
  }

  it('assertMatches throws when record missing', async () => {
    const { svc, prisma } = makeService();
    (prisma.passwordResetEmailCode.findUnique as jest.Mock).mockResolvedValue(null);
    await expect(svc.assertMatches('u1', '123456')).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
  });

  it('verifyAndConsume deletes record on valid code', async () => {
    const codeHash = '$2b$12$abcdefghijklmnopqrstuv';
    const { svc } = makeService();
    const tx = {
      passwordResetEmailCode: {
        findUnique: jest.fn().mockResolvedValue({
          userId: 'u1',
          codeHash,
          expiresAt: new Date(Date.now() + 60_000),
          attemptCount: 0,
        }),
        update: jest.fn(),
        delete: jest.fn(),
      },
    };

    jest.mock('../../src/otp/util/otp-code.util', () => ({
      verifyOtpCode: jest.fn().mockResolvedValue(true),
    }));

    (bcrypt.compare as jest.Mock).mockResolvedValue(true);

    await svc.verifyAndConsume(tx as never, 'u1', '123456');
    expect(tx.passwordResetEmailCode.delete).toHaveBeenCalledWith({
      where: { userId: 'u1' },
    });
  });
});
