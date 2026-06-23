/// <reference types="jest" />

import { ConflictException, ForbiddenException } from '@nestjs/common';
import { Role, UserStatus } from '../../src/prisma-client';
import { AdminUsersBulkWriteService } from '../../src/admin-users/services/admin-users-bulk-write.service';
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

function makeSvc(prisma: never) {
  const audit = { log: jest.fn().mockResolvedValue(undefined) } as never;
  const userEvents = { emitUserUpdated: jest.fn() } as never;
  const sessionRevocation = { revokeAllForUser: jest.fn().mockResolvedValue(undefined) };
  const authSnapshotCache = { invalidate: jest.fn() };
  const statusHistory = { recordStatusAction: jest.fn().mockResolvedValue(undefined) };
  return {
    svc: new AdminUsersBulkWriteService(
      prisma,
      audit,
      userEvents,
      sessionRevocation as never,
      authSnapshotCache as never,
      statusHistory as never,
    ),
    sessionRevocation,
    authSnapshotCache,
  };
}

describe('AdminUsersBulkWriteService', () => {
  it('bulk changeRole requires super admin', async () => {
    const prisma = {} as never;
    const { svc } = makeSvc(prisma);
    await expect(
      svc.bulk(
        { action: 'changeRole', userIds: ['u1'], role: Role.SUPPORT } as never,
        actor({ role: Role.ADMIN }),
      ),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('bulk changeRole requires role when action is changeRole', async () => {
    const prisma = {} as never;
    const { svc } = makeSvc(prisma);
    await expect(
      svc.bulk({ action: 'changeRole', userIds: ['u1'] } as never, actor({ role: Role.SUPER_ADMIN })),
    ).rejects.toBeInstanceOf(ConflictException);
  });

  it('bulk suspend revokes sessions for each updated user', async () => {
    const prisma = {
      user: {
        findMany: jest.fn().mockResolvedValue([
          { id: 'u1', role: Role.USER, status: UserStatus.ACTIVE },
          { id: 'u2', role: Role.USER, status: UserStatus.ACTIVE },
        ]),
        updateMany: jest.fn().mockResolvedValue({ count: 2 }),
      },
    } as never;
    const { svc, sessionRevocation, authSnapshotCache } = makeSvc(prisma);

    await svc.bulk({ action: 'suspend', userIds: ['u1', 'u2'] } as never, actor());

    expect(sessionRevocation.revokeAllForUser).toHaveBeenCalledTimes(2);
    expect(sessionRevocation.revokeAllForUser).toHaveBeenCalledWith('u1', 'status_changed');
    expect(sessionRevocation.revokeAllForUser).toHaveBeenCalledWith('u2', 'status_changed');
    expect(authSnapshotCache.invalidate).toHaveBeenCalledWith('u1');
    expect(authSnapshotCache.invalidate).toHaveBeenCalledWith('u2');
  });
});
