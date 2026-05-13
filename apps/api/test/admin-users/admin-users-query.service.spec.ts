/// <reference types="jest" />

import { NotFoundException } from '@nestjs/common';
import { Role, UserStatus } from '../../src/prisma-client';
import { AdminUsersQueryService } from '../../src/admin-users/admin-users-query.service';
import type { ListAdminUsersQueryDto } from '../../src/admin-users/dto/list-admin-users-query.dto';

describe('AdminUsersQueryService', () => {
  const audit = { listForUser: jest.fn() } as never;

  it('list maps rows and meta from transaction', async () => {
    const row = {
      id: 'u1',
      firstName: 'A',
      lastName: 'B',
      email: 'a@b.c',
      phoneNumber: '+38970000001',
      role: Role.USER,
      status: UserStatus.ACTIVE,
      lastActiveAt: new Date('2026-01-01T00:00:00.000Z'),
      pointsBalance: 0,
    };
    const prisma = {
      $transaction: jest.fn((ops: [Promise<unknown>, Promise<unknown>]) => Promise.all(ops)),
      user: {
        findMany: jest.fn().mockResolvedValue([row]),
        count: jest.fn().mockResolvedValue(1),
      },
    } as never;
    const svc = new AdminUsersQueryService(prisma, audit);
    const out = await svc.list({ page: 1, limit: 10 } as ListAdminUsersQueryDto);
    expect(out.data).toHaveLength(1);
    expect(out.data[0]!.lastActiveAt).toBe('2026-01-01T00:00:00.000Z');
    expect(out.meta).toEqual({ page: 1, limit: 10, total: 1 });
  });

  it('findOne throws when user missing', async () => {
    const prisma = {
      user: {
        findUnique: jest.fn().mockResolvedValue(null),
      },
    } as never;
    const svc = new AdminUsersQueryService(prisma, audit);
    await expect(svc.findOne('missing')).rejects.toBeInstanceOf(NotFoundException);
  });

  it('findOne returns counts when user exists', async () => {
    const prisma = {
      user: {
        findUnique: jest.fn().mockResolvedValue({
          id: 'u1',
          firstName: 'A',
          lastName: 'B',
          email: 'a@b.c',
          phoneNumber: '+1',
          role: Role.USER,
          status: UserStatus.ACTIVE,
          isPhoneVerified: true,
          pointsBalance: 1,
          totalPointsEarned: 2,
          totalPointsSpent: 0,
          lastActiveAt: null,
          createdAt: new Date('2026-01-02T00:00:00.000Z'),
          _count: { reports: 3 },
        }),
      },
      userSession: { count: jest.fn().mockResolvedValue(2) },
    } as never;
    const svc = new AdminUsersQueryService(prisma, audit);
    const out = await svc.findOne('u1');
    expect(out.reportsCount).toBe(3);
    expect(out.sessionsCount).toBe(2);
  });
});
