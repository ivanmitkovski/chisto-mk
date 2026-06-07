/// <reference types="jest" />
import { AuthSessionRevocationService } from '../../src/auth/services/auth-session-revocation.service';

describe('AuthSessionRevocationService', () => {
  it('revokeAllForUser marks active sessions revoked', async () => {
    const prisma = {
      userSession: {
        updateMany: jest.fn().mockResolvedValue({ count: 2 }),
      },
    };
    const audit = { log: jest.fn().mockResolvedValue(undefined) };
    const eventEmitter = { emit: jest.fn() };
    const authSnapshotCache = { invalidate: jest.fn() };
    const svc = new AuthSessionRevocationService(
      prisma as never,
      audit as never,
      eventEmitter as never,
      authSnapshotCache as never,
    );
    await svc.revokeAllForUser('u1', 'user_revoke_others');
    expect(prisma.userSession.updateMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({ userId: 'u1' }),
      }),
    );
    expect(eventEmitter.emit).toHaveBeenCalledWith('security.sessions_revoked', {
      userId: 'u1',
      reason: 'user_revoke_others',
    });
  });

  it('revokeSessionForUser revokes a single active session', async () => {
    const prisma = {
      userSession: {
        findFirst: jest.fn().mockResolvedValue({ id: 's1', revokedAt: null }),
        update: jest.fn().mockResolvedValue({ id: 's1' }),
      },
    };
    const audit = { log: jest.fn().mockResolvedValue(undefined) };
    const eventEmitter = { emit: jest.fn() };
    const authSnapshotCache = { invalidate: jest.fn() };
    const svc = new AuthSessionRevocationService(
      prisma as never,
      audit as never,
      eventEmitter as never,
      authSnapshotCache as never,
    );

    await expect(svc.revokeSessionForUser('u1', 's1', 'admin-1')).resolves.toEqual({ ok: true });

    expect(prisma.userSession.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { id: 's1' },
        data: expect.objectContaining({ revokedAt: expect.any(Date) }),
      }),
    );
    expect(authSnapshotCache.invalidate).toHaveBeenCalledWith('u1');
    expect(audit.log).toHaveBeenCalledWith(
      expect.objectContaining({
        action: 'SESSION_REVOKED_BY_ADMIN',
        resourceId: 's1',
      }),
    );
  });
});
