/// <reference types="jest" />

import * as bcrypt from 'bcrypt';
import { UserStatus } from '../../src/prisma-client';
import { RefreshTokenRotationService } from '../../src/auth/services/refresh-token-rotation.service';
import { loadAuthEnvRuntime } from '../../src/auth/constants/auth-env.config';

describe('RefreshTokenRotationService', () => {
  const env = loadAuthEnvRuntime(null);

  function makeRotation(overrides: {
    sessionRevocation?: { revokeSession: jest.Mock; revokeAllForUser: jest.Mock };
    replayCache?: { get: jest.Mock; set: jest.Mock };
  } = {}) {
    const sessionRevocation = overrides.sessionRevocation ?? {
      revokeSession: jest.fn().mockResolvedValue(undefined),
      revokeAllForUser: jest.fn().mockResolvedValue(undefined),
    };
    const replayCache = overrides.replayCache ?? {
      get: jest.fn().mockResolvedValue(null),
      set: jest.fn().mockResolvedValue(undefined),
    };
    const rotation = new RefreshTokenRotationService(
      {} as never,
      { log: jest.fn() } as never,
      { emit: jest.fn() } as never,
      sessionRevocation as never,
      env,
      replayCache as never,
    );
    return { rotation, sessionRevocation, replayCache };
  }

  it('returns replayed tokens within grace without revoking sessions', async () => {
    const rawRefreshToken = 'tid.grace-secret';
    const previousTokenHash = await bcrypt.hash(rawRefreshToken, 4);
    const replayResponse = {
      accessToken: 'replayed-access',
      refreshToken: 'replayed-refresh',
      user: { id: 'user-1' },
    };
    const { rotation, sessionRevocation, replayCache } = makeRotation({
      replayCache: {
        get: jest.fn().mockResolvedValue(replayResponse),
        set: jest.fn(),
      },
    });

    const session = {
      id: 'sess-1',
      userId: 'user-1',
      tokenId: 'tid',
      previousTokenHash,
      rotatedAt: new Date(Date.now() - 5_000),
      user: {
        id: 'user-1',
        status: UserStatus.ACTIVE,
      },
    };

    const result = await rotation.tryReplayPreviousRefreshToken(
      session as never,
      rawRefreshToken,
    );

    expect(result).toEqual(replayResponse);
    expect(sessionRevocation.revokeSession).not.toHaveBeenCalled();
    expect(sessionRevocation.revokeAllForUser).not.toHaveBeenCalled();
    expect(replayCache.get).toHaveBeenCalledWith(previousTokenHash);
  });

  it('revokes only the affected session when reuse is after grace', async () => {
    const rawRefreshToken = 'tid.stale-secret';
    const previousTokenHash = await bcrypt.hash(rawRefreshToken, 4);
    const eventEmitter = { emit: jest.fn() };
    const sessionRevocation = {
      revokeSession: jest.fn().mockResolvedValue(undefined),
      revokeAllForUser: jest.fn().mockResolvedValue(undefined),
    };
    const rotation = new RefreshTokenRotationService(
      {} as never,
      { log: jest.fn().mockResolvedValue(undefined) } as never,
      eventEmitter as never,
      sessionRevocation as never,
      env,
      { get: jest.fn(), set: jest.fn() } as never,
    );

    const session = {
      id: 'sess-stale',
      userId: 'user-1',
      tokenId: 'tid',
      previousTokenHash,
      rotatedAt: new Date(Date.now() - (env.refreshTokenRotationGraceSeconds + 10) * 1000),
      user: {
        id: 'user-1',
        status: UserStatus.ACTIVE,
      },
    };

    const result = await rotation.tryReplayPreviousRefreshToken(
      session as never,
      rawRefreshToken,
    );

    expect(result).toBeNull();
    expect(sessionRevocation.revokeSession).toHaveBeenCalledWith(
      'sess-stale',
      'user-1',
      'refresh_token_reuse',
    );
    expect(sessionRevocation.revokeAllForUser).not.toHaveBeenCalled();
    expect(eventEmitter.emit).toHaveBeenCalledWith(
      'security.refresh_token_reuse',
      expect.objectContaining({ userId: 'user-1', sessionId: 'sess-stale' }),
    );
  });
});
