/// <reference types="jest" />

import { ConflictException, ForbiddenException, NotFoundException } from '@nestjs/common';
import { Role, UserStatus } from '../../src/prisma-client';
import { AdminUsersWriteService } from '../../src/admin-users/admin-users-write.service';
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

describe('AdminUsersWriteService', () => {
  const audit = { log: jest.fn().mockResolvedValue(undefined) } as never;
  const userEvents = { emitUserUpdated: jest.fn() } as never;

  it('patchRole forbids changing own role', async () => {
    const prisma = {} as never;
    const svc = new AdminUsersWriteService(prisma, audit, userEvents);
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
    const svc = new AdminUsersWriteService(prisma, audit, userEvents);
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
    const svc = new AdminUsersWriteService(prisma, audit, userEvents);
    await expect(
      svc.patchRole('sa-1', { role: Role.ADMIN } as never, actor({ role: Role.ADMIN })),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('bulk changeRole requires super admin', async () => {
    const prisma = {} as never;
    const svc = new AdminUsersWriteService(prisma, audit, userEvents);
    await expect(
      svc.bulk(
        { action: 'changeRole', userIds: ['u1'], role: Role.SUPPORT } as never,
        actor({ role: Role.ADMIN }),
      ),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('bulk changeRole requires role when action is changeRole', async () => {
    const prisma = {} as never;
    const svc = new AdminUsersWriteService(prisma, audit, userEvents);
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
    const svc = new AdminUsersWriteService(prisma, audit, userEvents);
    await expect(
      svc.patch('u1', { phoneNumber: '+38970000099' } as never, actor()),
    ).rejects.toBeInstanceOf(ConflictException);
  });
});
