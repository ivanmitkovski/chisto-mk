/// <reference types="jest" />

import { BadRequestException, ForbiddenException, NotFoundException } from '@nestjs/common';
import { Role, UserStatus } from '../../src/prisma-client';
import { AdminUsersIdentifierService } from '../../src/admin-users/services/admin-users-identifier.service';
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

describe('AdminUsersIdentifierService', () => {
  it('requestEmailChange delegates with admin context', async () => {
    const identifierChange = {
      requestEmailChange: jest.fn().mockResolvedValue({ expiresIn: 600 }),
    };
    const prisma = {
      user: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'u1',
          email: 'old@test.local',
          role: Role.USER,
          status: UserStatus.ACTIVE,
        }),
      },
    };
    const userEvents = { emitUserUpdated: jest.fn() };
    const svc = new AdminUsersIdentifierService(
      prisma as never,
      identifierChange as never,
      userEvents as never,
    );

    await svc.requestEmailChange(
      'u1',
      { newEmail: 'new@test.local', reasonCode: 'user_request', note: 'support ticket' },
      actor(),
    );

    expect(identifierChange.requestEmailChange).toHaveBeenCalledWith('u1', 'new@test.local', {
      adminContext: {
        actorId: 'actor-1',
        reasonCode: 'user_request',
        note: 'support ticket',
      },
    });
  });

  it('requestEmailChange blocks deleted users', async () => {
    const prisma = {
      user: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'u1',
          email: 'old@test.local',
          role: Role.USER,
          status: UserStatus.DELETED,
        }),
      },
    };
    const svc = new AdminUsersIdentifierService(prisma as never, {} as never, {} as never);
    await expect(
      svc.requestEmailChange('u1', { newEmail: 'new@test.local', reasonCode: 'user_request' }, actor()),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('requestEmailChange blocks non-super-admin editing super admin', async () => {
    const prisma = {
      user: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'u1',
          email: 'sa@test.local',
          role: Role.SUPER_ADMIN,
          status: UserStatus.ACTIVE,
        }),
      },
    };
    const svc = new AdminUsersIdentifierService(prisma as never, {} as never, {} as never);
    await expect(
      svc.requestEmailChange('u1', { newEmail: 'new@test.local', reasonCode: 'user_request' }, actor()),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('confirmEmailChange creates moderation note and emits update', async () => {
    const identifierChange = {
      confirmEmailChange: jest.fn().mockResolvedValue({
        initiatedBy: 'admin',
        adminContext: { actorId: 'actor-1', reasonCode: 'user_request', note: 'ticket #1' },
      }),
    };
    const prisma = {
      user: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'u1',
          email: 'old@test.local',
          role: Role.USER,
          status: UserStatus.ACTIVE,
        }),
      },
      userModerationNote: {
        create: jest.fn().mockResolvedValue({ id: 'note-1' }),
      },
    };
    const userEvents = { emitUserUpdated: jest.fn() };
    const svc = new AdminUsersIdentifierService(
      prisma as never,
      identifierChange as never,
      userEvents as never,
    );

    const out = await svc.confirmEmailChange(
      'u1',
      { newEmail: 'new@test.local', code: '123456' },
      actor(),
    );

    expect(out).toEqual({ ok: true });
    expect(prisma.userModerationNote.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          userId: 'u1',
          authorId: 'actor-1',
          body: expect.stringContaining('user_request'),
        }),
      }),
    );
    expect(userEvents.emitUserUpdated).toHaveBeenCalledWith('u1');
  });

  it('confirmEmailChange rejects missing user', async () => {
    const prisma = {
      user: { findUnique: jest.fn().mockResolvedValue(null) },
    };
    const svc = new AdminUsersIdentifierService(prisma as never, {} as never, {} as never);
    await expect(
      svc.confirmEmailChange('missing', { newEmail: 'new@test.local', code: '123456' }, actor()),
    ).rejects.toBeInstanceOf(NotFoundException);
  });
});
