/// <reference types="jest" />
import { createHash } from 'node:crypto';
import { AuthIdentifierChangeService } from '../../src/auth/services/auth-identifier-change.service';

describe('AuthIdentifierChangeService', () => {
  function makeSvc(overrides: {
    prisma?: Record<string, unknown>;
    sessionRevocation?: { revokeAllForUser: jest.Mock };
    redisGet?: string | null;
  } = {}) {
    delete process.env.REDIS_URL;
    const prisma = {
      user: {
        findFirst: jest.fn().mockResolvedValue(null),
        findUnique: jest.fn().mockResolvedValue({ id: 'u1', email: 'old@test.local', firstName: 'A' }),
        update: jest.fn().mockResolvedValue({}),
        ...(overrides.prisma?.user as object),
      },
      ...(overrides.prisma ?? {}),
    };
    const throttle = { assertAllowed: jest.fn() };
    const email = { sendTemplate: jest.fn(), sendAuthTemplate: jest.fn() };
    const authSnapshotCache = { invalidate: jest.fn() };
    const audit = { log: jest.fn() };
    const sessionRevocation = overrides.sessionRevocation ?? {
      revokeAllForUser: jest.fn().mockResolvedValue(1),
    };
    const otpSender = { sendOtp: jest.fn() };
    const env = { shouldReturnDevCode: false };
    const svc = new AuthIdentifierChangeService(
      prisma as never,
      email as never,
      authSnapshotCache as never,
      audit as never,
      throttle as never,
      sessionRevocation as never,
      otpSender as never,
      env as never,
    );

    const redis = {
      set: jest.fn().mockResolvedValue('OK'),
      get: jest.fn().mockResolvedValue(overrides.redisGet ?? null),
      del: jest.fn().mockResolvedValue(1),
      connect: jest.fn(),
      quit: jest.fn(),
    };
    (svc as unknown as { redis: typeof redis }).redis = redis;
    return { svc, prisma, sessionRevocation, audit, redis };
  }

  it('requestEmailChange rejects duplicate email', async () => {
    const { svc, prisma } = makeSvc({
      prisma: {
        user: {
          findFirst: jest.fn().mockResolvedValue({ id: 'other' }),
          findUnique: jest.fn().mockResolvedValue({ id: 'u1', email: 'old@test.local', firstName: 'A' }),
        },
      },
    });
    await expect(svc.requestEmailChange('u1', 'taken@test.local')).rejects.toMatchObject({
      response: { code: 'EMAIL_IN_USE' },
    });
    void prisma;
  });

  it('confirmEmailChange revokes sessions and logs admin metadata', async () => {
    const code = '123456';
    const codeHash = createHash('sha256').update(code).digest('hex');
    const pending = JSON.stringify({
      kind: 'email',
      newValue: 'new@test.local',
      codeHash,
      expiresAt: new Date(Date.now() + 60_000).toISOString(),
      adminContext: { actorId: 'admin-1', reasonCode: 'user_request' },
    });
    const { svc, sessionRevocation, audit } = makeSvc({ redisGet: pending });

    const result = await svc.confirmEmailChange('u1', 'new@test.local', code);

    expect(sessionRevocation.revokeAllForUser).toHaveBeenCalledWith('u1', 'identifier_changed');
    expect(audit.log).toHaveBeenCalledWith(
      expect.objectContaining({
        actorId: 'admin-1',
        action: 'IDENTIFIER_CHANGED',
        metadata: expect.objectContaining({
          field: 'email',
          initiatedBy: 'admin',
          reasonCode: 'user_request',
        }),
      }),
    );
    expect(result).toEqual({
      initiatedBy: 'admin',
      adminContext: { actorId: 'admin-1', reasonCode: 'user_request' },
    });
  });
});
