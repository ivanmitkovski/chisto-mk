/// <reference types="jest" />

import { ExecutionContext, ForbiddenException, UnauthorizedException } from '@nestjs/common';
import { PhoneVerifiedGuard } from '../../src/auth/phone-verified.guard';

function mockContext(user?: { userId: string }): ExecutionContext {
  return {
    switchToHttp: () => ({
      getRequest: () => ({ user }),
    }),
  } as ExecutionContext;
}

describe('PhoneVerifiedGuard', () => {
  it('requires authenticated user', async () => {
    const prisma = { user: { findUnique: jest.fn() } };
    const guard = new PhoneVerifiedGuard(prisma as never);
    await expect(guard.canActivate(mockContext())).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
  });

  it('rejects unverified phone', async () => {
    const prisma = {
      user: {
        findUnique: jest.fn().mockResolvedValue({
          isPhoneVerified: false,
          status: 'ACTIVE',
        }),
      },
    };
    const guard = new PhoneVerifiedGuard(prisma as never);
    await expect(
      guard.canActivate(mockContext({ userId: 'user-1' })),
    ).rejects.toMatchObject({
      response: expect.objectContaining({ code: 'PHONE_NOT_VERIFIED' }),
    });
    await expect(
      guard.canActivate(mockContext({ userId: 'user-1' })),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('allows verified user', async () => {
    const prisma = {
      user: {
        findUnique: jest.fn().mockResolvedValue({
          isPhoneVerified: true,
          status: 'ACTIVE',
        }),
      },
    };
    const guard = new PhoneVerifiedGuard(prisma as never);
    await expect(guard.canActivate(mockContext({ userId: 'user-1' }))).resolves.toBe(
      true,
    );
  });
});
