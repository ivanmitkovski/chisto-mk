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
  let lastInviteUrl: string | undefined;

  const env = { saltRounds: 4 };
  const actor = { userId: 'super-1', role: Role.SUPER_ADMIN, email: 'sa@chisto.mk' };

  beforeEach(() => {
    invites = [];
    users = [];
    auditActions = [];
    emailSent = false;
    lastInviteUrl = undefined;

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
      sendAdminInviteEmail: async (_to: string, ctx: { inviteUrl: string }) => {
        emailSent = true;
        lastInviteUrl = ctx.inviteUrl;
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
    expect(lastInviteUrl).toMatch(/^https:\/\/admin\.chisto\.mk\/accept-invite\?/);
    expect(lastInviteUrl).not.toContain('localhost');
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

  it('uses production admin URL when ADMIN_APP_BASE_URL is unset', async () => {
    const configWithoutAdminUrl = {
      get: (key: string) => (key === 'ADMIN_INVITE_TTL_HOURS' ? '72' : undefined),
    };
    const email = {
      sendAdminInviteEmail: async (_to: string, ctx: { inviteUrl: string }) => {
        lastInviteUrl = ctx.inviteUrl;
      },
    };
    const svc = new AdminInvitesService(
      {
        adminInvite: {
          findMany: async () => [],
          findFirst: async () => null,
          findUnique: async () => null,
          create: async ({ data }: { data: Record<string, unknown> }) => ({
            id: 'inv-new',
            createdAt: new Date(),
            acceptedAt: null,
            revokedAt: null,
            status: AdminInviteStatus.PENDING,
            invitedBy: { id: actor.userId, email: actor.email, firstName: 'Super', lastName: 'Admin' },
            ...data,
          }),
          update: async () => ({}),
        },
        user: { findUnique: async () => null },
      } as never,
      configWithoutAdminUrl as never,
      email as never,
      { log: async () => {} } as never,
      env as never,
    );

    await svc.create(
      { email: 'new@chisto.mk', firstName: 'New', lastName: 'Mod', role: Role.SUPPORT },
      actor as never,
    );

    expect(lastInviteUrl).toMatch(/^https:\/\/admin\.chisto\.mk\/accept-invite\?/);
    expect(lastInviteUrl).not.toContain('localhost');
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
