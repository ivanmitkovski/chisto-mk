/// <reference types="jest" />

import { Role } from '../../src/prisma-client';
import { AdminUsersSessionWriteService } from '../../src/admin-users/services/admin-users-session-write.service';
import type { AuthenticatedUser } from '../../src/auth/types/authenticated-user.type';

function actor(overrides: Partial<AuthenticatedUser> = {}): AuthenticatedUser {
  return {
    userId: 'actor-1',
    email: 'actor@chisto.mk',
    phoneNumber: '+38970000002',
    role: Role.ADMIN,
    ...overrides,
  };
}

describe('AdminUsersSessionWriteService', () => {
  it('revokeSession delegates to session revocation service', async () => {
    const sessionRevocation = {
      revokeSessionForUser: jest.fn().mockResolvedValue({ ok: true }),
      revokeAllForUser: jest.fn(),
    };
    const prisma = {
      user: {
        findUnique: jest.fn().mockResolvedValue({ id: 'u1', role: Role.USER }),
      },
    } as never;
    const svc = new AdminUsersSessionWriteService(
      prisma,
      { log: jest.fn() } as never,
      { emitUserUpdated: jest.fn() } as never,
      sessionRevocation as never,
      { invalidate: jest.fn() } as never,
    );

    await expect(svc.revokeSession('u1', 'session-1', actor())).resolves.toEqual({ ok: true });
    expect(sessionRevocation.revokeSessionForUser).toHaveBeenCalledWith('u1', 'session-1', 'actor-1');
  });
});
