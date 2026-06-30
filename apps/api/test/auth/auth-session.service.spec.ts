/// <reference types="jest" />

import { UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as bcrypt from 'bcrypt';
import { UserStatus } from '../../src/prisma-client';
import { AuthSessionService } from '../../src/auth/services/auth-session.service';
import { RefreshTokenRotationService } from '../../src/auth/services/refresh-token-rotation.service';
import { loadAuthEnvRuntime } from '../../src/auth/constants/auth-env.config';

function daysFromNow(days: number): Date {
  const d = new Date();
  d.setDate(d.getDate() + days);
  return d;
}

function makeService(overrides: {
  prisma?: Record<string, unknown>;
  env?: ReturnType<typeof loadAuthEnvRuntime>;
} = {}) {
  const env = overrides.env ?? loadAuthEnvRuntime(null as never);
  const prisma = overrides.prisma ?? {};
  const jwt = { sign: jest.fn().mockReturnValue('access-token') } as unknown as JwtService;
  const uploads = { signPrivateObjectKey: jest.fn() } as never;
  const audit = { log: jest.fn() } as never;
  const emitter = { emit: jest.fn() } as never;
  const sessionRevocation = { revokeAllForUser: jest.fn() } as never;
  const configService = {
    get: jest.fn((key: string) => (key === 'TERMS_VERSION' ? '1' : undefined)),
  } as unknown as ConfigService;
  const replayCache = { get: jest.fn(), set: jest.fn() } as never;
  const rotation = new RefreshTokenRotationService(
    prisma as never,
    audit as never,
    emitter as never,
    sessionRevocation,
    env,
    replayCache,
  );
  const session = new AuthSessionService(
    prisma as never,
    jwt,
    uploads as never,
    sessionRevocation,
    env,
    configService,
    rotation,
    emitter as never,
  );
  return { session, prisma, env, jwt, emitter, replayCache };
}

describe('AuthSessionService', () => {
  it('refresh rejects token without dot separator', async () => {
    const { session } = makeService();
    await expect(session.refresh('nodotseparator')).rejects.toBeInstanceOf(UnauthorizedException);
  });

  it('creates session with 7-day expiry when rememberMe is false', async () => {
    const user = {
      id: 'user-1',
      status: UserStatus.ACTIVE,
      role: 'USER',
      email: 'u@chisto.mk',
      phoneNumber: '+38970123456',
    };
    const create = jest.fn().mockResolvedValue({ id: 'sess-1', userId: user.id });
    const prisma = {
      userSession: {
        findUnique: jest.fn(),
        findFirst: jest.fn().mockResolvedValue(null),
        findMany: jest.fn().mockResolvedValue([]),
        create,
      },
    };
    const { session, env } = makeService({ prisma });
    await session.buildAuthResponse(user as never, false, { deviceId: 'device-1' });

    expect(create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          rememberMe: false,
          expiresAt: expect.any(Date),
        }),
      }),
    );
    const expiresAt = create.mock.calls[0][0].data.expiresAt as Date;
    const expected = daysFromNow(env.refreshTokenStandardDays);
    expect(Math.abs(expiresAt.getTime() - expected.getTime())).toBeLessThan(5_000);
  });

  it('creates session with 90-day expiry when rememberMe is true', async () => {
    const user = {
      id: 'user-1',
      status: UserStatus.ACTIVE,
      role: 'USER',
      email: 'u@chisto.mk',
      phoneNumber: '+38970123456',
    };
    const create = jest.fn().mockResolvedValue({ id: 'sess-1', userId: user.id });
    const prisma = {
      userSession: {
        findUnique: jest.fn(),
        findFirst: jest.fn().mockResolvedValue(null),
        findMany: jest.fn().mockResolvedValue([]),
        create,
      },
    };
    const { session, env } = makeService({ prisma });
    await session.buildAuthResponse(user as never, true, { deviceId: 'device-1' });

    const expiresAt = create.mock.calls[0][0].data.expiresAt as Date;
    const expected = daysFromNow(env.refreshTokenTtlDays);
    expect(Math.abs(expiresAt.getTime() - expected.getTime())).toBeLessThan(5_000);
  });

  it('refresh preserves rememberMe=false sliding window (does not jump to 90 days)', async () => {
    const tokenId = 'abc123';
    const tokenSecret = 'secretpart';
    const rawRefreshToken = `${tokenId}.${tokenSecret}`;
    const refreshTokenHash = await bcrypt.hash(rawRefreshToken, 12);
    const sessionRecord = {
      id: 'sess-1',
      tokenId,
      refreshTokenHash,
      previousTokenHash: null,
      rotatedAt: null,
      revokedAt: null,
      rememberMe: false,
      expiresAt: daysFromNow(6),
      deviceId: 'device-1',
      user: {
        id: 'user-1',
        status: UserStatus.ACTIVE,
        role: 'USER',
        email: 'u@chisto.mk',
        phoneNumber: '+38970123456',
      },
    };
    const updateMany = jest.fn().mockResolvedValue({ count: 1 });
    const prisma = {
      userSession: {
        findUnique: jest.fn().mockResolvedValue(sessionRecord),
        updateMany,
      },
    };
    const { session, env } = makeService({ prisma });
    await session.refresh(rawRefreshToken, 'device-1');

    expect(updateMany).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          rememberMe: false,
          expiresAt: expect.any(Date),
        }),
      }),
    );
    const expiresAt = updateMany.mock.calls[0][0].data.expiresAt as Date;
    const expected = daysFromNow(env.refreshTokenStandardDays);
    expect(Math.abs(expiresAt.getTime() - expected.getTime())).toBeLessThan(5_000);
  });
});
