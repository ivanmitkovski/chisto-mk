/// <reference types="jest" />
import { ConflictException, BadRequestException } from '@nestjs/common';
import { AdminInviteStatus, Role, UserStatus } from '../../src/prisma-client';
import { AdminInvitesService } from '../../src/admin-invites/services/admin-invites.service';

describe('AdminInvitesService', () => {
  let service: AdminInvitesService;
  let invites: Array<Record<string, unknown>>;
  let users: Array<Record<string, unknown>>;
  let auditActions: string[];
  let emailSent: boolean;

  const env = { saltRounds: 4 };
  const actor = { userId: 'super-1', role: Role.SUPER_ADMIN, email: 'sa@chisto.mk' };

  beforeEach(() => {
    invites = [];
    users = [];
    auditActions = [];
    emailSent = false;

    const prisma = {
      adminInvite: {
        findMany: async () => invites,
        findFirst: async ({ where }: { where: { email?: string; status?: AdminInviteStatus } }) =>
          invites.find(
            (row) =>
              (where.email == null || row.email === where.email) &&
              (where.status == null || row.status === where.status),
          ) ?? null,
        findUnique: async ({ where }: { where: { id: string } }) =>
          invites.find((row) => row.id === where.id) ?? null,
        create: async ({ data, include }: { data: Record<string, unknown>; include?: unknown }) => {
          const row = {
            id: `inv-${invites.length + 1}`,
            createdAt: new Date(),
            acceptedAt: null,
            revokedAt: null,
            status: AdminInviteStatus.PENDING,
            invitedBy: {
              id: actor.userId,
              email: actor.email,
              firstName: 'Super',
              lastName: 'Admin',
            },
            ...data,
          };
          invites.push(row);
          if (include) return row;
          return row;
        },
        update: async ({
          where,
          data,
          include,
        }: {
          where: { id: string };
          data: Record<string, unknown>;
          include?: unknown;
        }) => {
          const idx = invites.findIndex((row) => row.id === where.id);
          if (idx < 0) throw new Error('missing invite');
          invites[idx] = { ...invites[idx], ...data };
          if (include) return invites[idx];
          return invites[idx];
        },
      },
      user: {
        findUnique: async ({ where }: { where: { email?: string } }) =>
          users.find((row) => row.email === where.email) ?? null,
      },
    };

    const config = {
      get: (key: string) => {
        if (key === 'ADMIN_INVITE_TTL_HOURS') return '72';
        if (key === 'ADMIN_APP_BASE_URL') return 'https://admin.chisto.mk';
        return undefined;
      },
    };

    const email = {
      sendAdminInviteEmail: async () => {
        emailSent = true;
      },
    };

    const audit = {
      log: async ({ action }: { action: string }) => {
        auditActions.push(action);
      },
    };

    service = new AdminInvitesService(prisma as never, config as never, email as never, audit as never, env as never);
  });

  it('creates a pending invite and sends email', async () => {
    const result = await service.create(
      {
        email: 'mod@chisto.mk',
        firstName: 'Mod',
        lastName: 'Erator',
        role: Role.SUPPORT,
      },
      actor as never,
    );

    expect(result.status).toBe(AdminInviteStatus.PENDING);
    expect(result.email).toBe('mod@chisto.mk');
    expect(emailSent).toBe(true);
    expect(auditActions).toContain('ADMIN_INVITE_CREATED');
  });

  it('rejects duplicate active user email', async () => {
    users.push({ email: 'mod@chisto.mk', status: UserStatus.ACTIVE });
    await expect(
      service.create(
        {
          email: 'mod@chisto.mk',
          firstName: 'Mod',
          lastName: 'Erator',
          role: Role.SUPPORT,
        },
        actor as never,
      ),
    ).rejects.toBeInstanceOf(ConflictException);
  });

  it('resends when a pending invite already exists', async () => {
    invites.push({
      id: 'inv-1',
      email: 'mod@chisto.mk',
      firstName: 'Mod',
      lastName: 'Erator',
      role: Role.SUPPORT,
      status: AdminInviteStatus.PENDING,
      tokenHash: 'old',
      expiresAt: new Date(Date.now() + 3600_000),
      createdAt: new Date(),
      invitedById: actor.userId,
      invitedBy: { id: actor.userId, email: actor.email, firstName: 'Super', lastName: 'Admin' },
    });

    const result = await service.create(
      {
        email: 'mod@chisto.mk',
        firstName: 'Mod',
        lastName: 'Erator',
        role: Role.SUPPORT,
      },
      actor as never,
    );

    expect(result.id).toBe('inv-1');
    expect(auditActions).toContain('ADMIN_INVITE_RESENT');
    expect(emailSent).toBe(true);
  });

  it('rejects invalid invite roles', async () => {
    await expect(
      service.create(
        {
          email: 'user@chisto.mk',
          firstName: 'Citizen',
          lastName: 'User',
          role: Role.USER as never,
        },
        actor as never,
      ),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('revokes a pending invite', async () => {
    invites.push({
      id: 'inv-1',
      email: 'mod@chisto.mk',
      status: AdminInviteStatus.PENDING,
    });

    const result = await service.revoke('inv-1', actor as never);
    expect(result.status).toBe(AdminInviteStatus.REVOKED);
    expect(auditActions).toContain('ADMIN_INVITE_REVOKED');
  });
});
