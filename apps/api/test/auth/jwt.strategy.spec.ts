/// <reference types="jest" />

import { UnauthorizedException } from '@nestjs/common';
import { UserStatus, Role } from '../../src/prisma-client';
import { JwtStrategy } from '../../src/auth/jwt.strategy';

describe('JwtStrategy', () => {
  const authSnapshotCache = {
    get: jest.fn(),
    set: jest.fn(),
    invalidate: jest.fn(),
  };

  function makeStrategy() {
    process.env.JWT_SECRET = 'test-jwt-secret-at-least-32-chars-long';
    const prisma = {
      userSession: {
        findFirst: jest.fn().mockResolvedValue({ id: 'sess-1' }),
      },
      user: {
        findUnique: jest.fn().mockResolvedValue({
          status: UserStatus.ACTIVE,
          role: Role.USER,
          email: 'u@chisto.mk',
          phoneNumber: '+38970123456',
        }),
      },
    };
    const strategy = new JwtStrategy(null, prisma as never, authSnapshotCache as never);
    return { strategy, prisma, authSnapshotCache };
  }

  beforeEach(() => {
    jest.clearAllMocks();
    authSnapshotCache.get.mockReturnValue(null);
  });

  it('rejects access tokens without sid', async () => {
    const { strategy } = makeStrategy();
    await expect(
      strategy.validate({ sub: 'user-1', role: Role.USER }),
    ).rejects.toBeInstanceOf(UnauthorizedException);
  });

  it('reloads role from DB snapshot cache miss', async () => {
    const { strategy, prisma } = makeStrategy();
    const user = await strategy.validate({
      sub: 'user-1',
      role: Role.ADMIN,
      sid: 'sess-1',
    });
    expect(user.role).toBe(Role.USER);
    expect(prisma.user.findUnique).toHaveBeenCalled();
  });

  it('rejects revoked or missing sessions', async () => {
    const { strategy, prisma } = makeStrategy();
    prisma.userSession.findFirst.mockResolvedValue(null);
    await expect(
      strategy.validate({ sub: 'user-1', role: Role.USER, sid: 'sess-gone' }),
    ).rejects.toMatchObject({ response: { code: 'SESSION_REVOKED' } });
  });
});
