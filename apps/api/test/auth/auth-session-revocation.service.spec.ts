/// <reference types="jest" />
import { AuthSessionRevocationService } from '../../src/auth/auth-session-revocation.service';

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
});
