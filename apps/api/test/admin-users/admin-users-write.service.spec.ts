/// <reference types="jest" />

import { ConflictException, ForbiddenException, NotFoundException } from '@nestjs/common';
import { Role, UserStatus } from '../../src/prisma-client';
import { AdminUsersWriteService } from '../../src/admin-users/services/admin-users-write.service';
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
  const sessionRevocation = { revokeAllForUser: jest.fn().mockResolvedValue(undefined), revokeSessionForUser: jest.fn().mockResolvedValue({ ok: true }) };
  const authSnapshotCache = { invalidate: jest.fn() };
  const accountErasure = { eraseUserAccount: jest.fn().mockResolvedValue(undefined) };
  return {
    svc: new AdminUsersWriteService(
      prisma,
      audit,
      userEvents,
      sessionRevocation as never,
      authSnapshotCache as never,
      accountErasure as never,
    ),
    sessionRevocation,
    accountErasure,
    authSnapshotCache,
  };
}

describe('AdminUsersWriteService', () => {

  it('patchRole forbids changing own role', async () => {
    const prisma = {} as never;
    const { svc } = makeSvc(prisma);
    await expect(
      svc.patchRole(
        'actor-1',
        { role: Role.SUPPORT } as never,
        actor({ userId: 'actor-1', role: Role.ADMIN }),
      ),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('patchRole throws when user not found', async () => {
    const prisma = {
      user: { findUnique: jest.fn().mockResolvedValue(null) },
    } as never;
    const { svc } = makeSvc(prisma);
    await expect(
      svc.patchRole('missing', { role: Role.USER } as never, actor({ role: Role.SUPER_ADMIN })),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('patchRole forbids non-super-admin from editing super admin', async () => {
    const prisma = {
      user: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'sa-1',
          role: Role.SUPER_ADMIN,
          status: UserStatus.ACTIVE,
          firstName: 'S',
          lastName: 'A',
          phoneNumber: '+38970000003',
        }),
      },
    } as never;
    const { svc } = makeSvc(prisma);
    await expect(
      svc.patchRole('sa-1', { role: Role.ADMIN } as never, actor({ role: Role.ADMIN })),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

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

  it('patch rejects duplicate phone', async () => {
    const prisma = {
      user: {
        findUnique: jest
          .fn()
          .mockResolvedValueOnce({
            id: 'u1',
            role: Role.USER,
            status: UserStatus.ACTIVE,
            firstName: 'A',
            lastName: 'B',
            phoneNumber: '+38970000001',
          })
          .mockResolvedValueOnce({ id: 'other' }),
        findFirst: jest.fn().mockResolvedValue({ id: 'other' }),
      },
    } as never;
    const { svc } = makeSvc(prisma);
    await expect(
      svc.patch('u1', { phoneNumber: '+38970000099' } as never, actor()),
    ).rejects.toBeInstanceOf(ConflictException);
  });

  it('patchRole does not revoke sessions for role changes', async () => {
    const prisma = {
      user: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'u1',
          role: Role.USER,
          status: UserStatus.ACTIVE,
          firstName: 'A',
          lastName: 'B',
          phoneNumber: '+38970000001',
        }),
        update: jest.fn().mockResolvedValue({
          id: 'u1',
          role: Role.ADMIN,
          status: UserStatus.ACTIVE,
        }),
      },
    } as never;
    const { svc, sessionRevocation } = makeSvc(prisma);

    await svc.patchRole('u1', { role: Role.ADMIN } as never, actor({ role: Role.SUPER_ADMIN }));

    expect(sessionRevocation.revokeAllForUser).not.toHaveBeenCalled();
  });

  it('patch revokes sessions when status becomes suspended', async () => {
    const updatedUser = {
      id: 'u1',
      role: Role.USER,
      status: UserStatus.SUSPENDED,
      firstName: 'A',
      lastName: 'B',
      phoneNumber: '+38970000001',
    };
    const prisma = {
      user: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'u1',
          role: Role.USER,
          status: UserStatus.ACTIVE,
          firstName: 'A',
          lastName: 'B',
          phoneNumber: '+38970000001',
        }),
        findFirst: jest.fn().mockResolvedValue(null),
        update: jest.fn().mockResolvedValue(updatedUser),
        findUniqueOrThrow: jest.fn().mockResolvedValue(updatedUser),
      },
      userStatusAction: {
        create: jest.fn().mockResolvedValue({ id: 'action-1' }),
      },
    } as never;
    const { svc, sessionRevocation } = makeSvc(prisma);

    await svc.patch('u1', { status: UserStatus.SUSPENDED } as never, actor());

    expect(sessionRevocation.revokeAllForUser).toHaveBeenCalledWith('u1', 'status_changed');
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
      userStatusAction: {
        create: jest.fn().mockResolvedValue({ id: 'action-1' }),
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

  it('patch routes status DELETED through account erasure', async () => {
    const updatedUser = {
      id: 'u1',
      role: Role.USER,
      status: UserStatus.DELETED,
      firstName: '',
      lastName: '',
      phoneNumber: '+38970000001',
    };
    const prisma = {
      user: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'u1',
          role: Role.USER,
          status: UserStatus.ACTIVE,
          firstName: 'A',
          lastName: 'B',
          phoneNumber: '+38970000001',
        }),
        findFirst: jest.fn().mockResolvedValue(null),
        update: jest.fn().mockResolvedValue(updatedUser),
        findUniqueOrThrow: jest.fn().mockResolvedValue(updatedUser),
      },
    } as never;
    const { svc, sessionRevocation, accountErasure } = makeSvc(prisma);

    await svc.patch('u1', { status: UserStatus.DELETED } as never, actor());

    expect(accountErasure.eraseUserAccount).toHaveBeenCalledWith('u1');
    expect(sessionRevocation.revokeAllForUser).not.toHaveBeenCalled();
  });

  it('revokeSession delegates to session revocation service', async () => {
    const prisma = {
      user: {
        findUnique: jest.fn().mockResolvedValue({ id: 'u1', role: Role.USER }),
      },
    } as never;
    const { svc, sessionRevocation } = makeSvc(prisma);

    await expect(svc.revokeSession('u1', 'session-1', actor())).resolves.toEqual({ ok: true });
    expect(sessionRevocation.revokeSessionForUser).toHaveBeenCalledWith('u1', 'session-1', 'actor-1');
  });
});
