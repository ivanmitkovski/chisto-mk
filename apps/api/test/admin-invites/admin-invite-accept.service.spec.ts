/// <reference types="jest" />
jest.mock('otplib', () => ({
  generateSecret: jest.fn(() => 'invite-mfa-secret'),
  generateURI: jest.fn(() => 'otpauth://totp/test'),
  verify: jest.fn(({ token }: { token: string }) => ({ valid: token === '123456' })),
}));

import * as bcrypt from 'bcrypt';
import { BadRequestException, UnauthorizedException } from '@nestjs/common';
import { AdminInviteStatus, Role, UserStatus } from '../../src/prisma-client';
import { AdminInviteAcceptService } from '../../src/admin-invites/services/admin-invite-accept.service';

describe('AdminInviteAcceptService', () => {
  let service: AdminInviteAcceptService;
  let invites: Array<Record<string, unknown>>;
  let users: Array<Record<string, unknown>>;
  let auditMetadata: Array<Record<string, unknown>>;

  const env = { saltRounds: 4 };
  const token = 'raw-invite-token';
  let tokenHash = '';

  beforeEach(async () => {
    tokenHash = await bcrypt.hash(token, env.saltRounds);
    invites = [
      {
        id: 'inv-1',
        email: 'mod@chisto.mk',
        firstName: 'Mod',
        lastName: 'Erator',
        role: Role.SUPPORT,
        status: AdminInviteStatus.PENDING,
        expiresAt: new Date(Date.now() + 3600_000),
        tokenHash,
        mfaSecret: null,
        attemptCount: 0,
      },
    ];
    users = [];
    auditMetadata = [];

    const prisma = {
      adminInvite: {
        findUnique: async ({ where }: { where: { id: string } }) =>
          invites.find((row) => row.id === where.id) ?? null,
        update: async ({
          where,
          data,
        }: {
          where: { id: string };
          data: Record<string, unknown>;
        }) => {
          const idx = invites.findIndex((row) => row.id === where.id);
          if (idx < 0) throw new Error('missing invite');
          invites[idx] = { ...invites[idx], ...data };
          return invites[idx];
        },
      },
      user: {
        findUnique: async ({ where }: { where: { email?: string; phoneNumber?: string } }) => {
          if (where.email) {
            return users.find((row) => row.email === where.email) ?? null;
          }
          if (where.phoneNumber) {
            return users.find((row) => row.phoneNumber === where.phoneNumber) ?? null;
          }
          return null;
        },
        create: async ({ data }: { data: Record<string, unknown> }) => {
          const created = { id: `user-${users.length + 1}`, ...data };
          users.push(created);
          return created;
        },
      },
      $transaction: async (fn: (tx: unknown) => Promise<unknown>) => fn(prisma),
    } as never;

    const audit = {
      log: async ({ metadata }: { metadata?: Record<string, unknown> }) => {
        if (metadata) auditMetadata.push(metadata);
      },
    };

    const sessionService = {
      buildAuthResponse: async (user: { id: string; role: Role; email: string }) => ({
        accessToken: 'access',
        refreshToken: 'refresh',
        user: { id: user.id, role: user.role, email: user.email },
      }),
    };

    service = new AdminInviteAcceptService(
      prisma as never,
      audit as never,
      sessionService as never,
      env as never,
    );
  });

  it('accepts invite without totpCode and creates user without MFA', async () => {
    const result = await service.accept({
      id: 'inv-1',
      token,
      password: 'StrongPass123!',
      phoneNumber: '+38970123456',
      deviceId: 'device-1',
    });

    expect(result.backupCodes).toEqual([]);
    expect(users[0]).toMatchObject({
      email: 'mod@chisto.mk',
      phoneNumber: '+38970123456',
      totpSecret: null,
      mfaBackupCodes: [],
      status: UserStatus.ACTIVE,
    });
    expect(invites[0]).toMatchObject({
      status: AdminInviteStatus.ACCEPTED,
      mfaSecret: null,
    });
    expect(auditMetadata[0]).toEqual({ email: 'mod@chisto.mk', role: Role.SUPPORT, mfaEnrolled: false });
  });

  it('accepts invite with totpCode when MFA setup was started', async () => {
    invites[0].mfaSecret = 'invite-mfa-secret';

    const result = await service.accept({
      id: 'inv-1',
      token,
      password: 'StrongPass123!',
      phoneNumber: '+38970123456',
      totpCode: '123456',
      deviceId: 'device-1',
    });

    expect(result.backupCodes).toHaveLength(8);
    expect(users[0]).toMatchObject({
      totpSecret: 'invite-mfa-secret',
    });
    expect(Array.isArray(users[0].mfaBackupCodes)).toBe(true);
    expect((users[0].mfaBackupCodes as string[]).length).toBe(8);
    expect(auditMetadata[0]).toEqual({ email: 'mod@chisto.mk', role: Role.SUPPORT, mfaEnrolled: true });
  });

  it('rejects enroll accept when MFA setup was not started', async () => {
    await expect(
      service.accept({
        id: 'inv-1',
        token,
        password: 'StrongPass123!',
        phoneNumber: '+38970123456',
        totpCode: '123456',
        deviceId: 'device-1',
      }),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('rejects invalid totp during enroll accept', async () => {
    invites[0].mfaSecret = 'invite-mfa-secret';

    await expect(
      service.accept({
        id: 'inv-1',
        token,
        password: 'StrongPass123!',
        phoneNumber: '+38970123456',
        totpCode: '000000',
        deviceId: 'device-1',
      }),
    ).rejects.toBeInstanceOf(UnauthorizedException);
  });
});
