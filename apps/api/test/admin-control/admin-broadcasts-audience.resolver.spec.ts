/// <reference types="jest" />
import { BadRequestException } from '@nestjs/common';
import {
  AdminBroadcastsAudienceResolver,
  BROADCAST_RECIPIENT_CAP,
} from '../../src/admin-control/services/admin-broadcasts-audience.resolver';

describe('AdminBroadcastsAudienceResolver', () => {
  function createResolver(overrides?: {
    users?: Array<{ id: string; status: string; lastActiveAt?: Date }>;
    totalCount?: number;
  }) {
    const users = overrides?.users ?? [];
    const prisma = {
      user: {
        findMany: jest.fn(async ({ where, take }: { where?: Record<string, unknown>; take?: number }) => {
          if (where && 'id' in where && where.id && typeof where.id === 'object' && 'in' in where.id) {
            const ids = (where.id as { in: string[] }).in;
            return users
              .filter((user) => ids.includes(user.id))
              .filter((user) => !where.status || user.status === where.status)
              .map((user) => ({
                id: user.id,
                status: user.status,
                firstName: 'Test',
                lastName: 'User',
                email: `${user.id}@example.com`,
                phoneNumber: '',
              }));
          }

          let filtered = users.filter((user) => user.status === 'ACTIVE');
          if (where && 'lastActiveAt' in where) {
            const cutoff = (where.lastActiveAt as { gte: Date }).gte;
            filtered = filtered.filter(
              (user) => user.lastActiveAt && user.lastActiveAt >= cutoff,
            );
          }
          return filtered.slice(0, take ?? filtered.length).map((user) => ({ id: user.id }));
        }),
        count: jest.fn(async ({ where }: { where?: Record<string, unknown> }) => {
          let filtered = users.filter((user) => user.status === 'ACTIVE');
          if (where && 'lastActiveAt' in where) {
            const cutoff = (where.lastActiveAt as { gte: Date }).gte;
            filtered = filtered.filter(
              (user) => user.lastActiveAt && user.lastActiveAt >= cutoff,
            );
          }
          return overrides?.totalCount ?? filtered.length;
        }),
      },
    };
    return {
      resolver: new AdminBroadcastsAudienceResolver(prisma as never),
      prisma,
    };
  }

  it('resolves specific users to active IDs only', async () => {
    const { resolver } = createResolver({
      users: [
        { id: 'active-1', status: 'ACTIVE' },
        { id: 'suspended-1', status: 'SUSPENDED' },
      ],
    });

    const ids = await resolver.resolveAudienceUserIds({
      audience: 'users',
      audienceUserIds: ['active-1', 'suspended-1'],
    });
    expect(ids).toEqual(['active-1']);
  });

  it('counts all active users with cap flag', async () => {
    const { resolver } = createResolver({
      users: [],
      totalCount: BROADCAST_RECIPIENT_CAP + 10,
    });

    const result = await resolver.countAudience({ audience: 'all', audienceUserIds: [] });
    expect(result.recipientCount).toBe(BROADCAST_RECIPIENT_CAP);
    expect(result.capped).toBe(true);
    expect(result.cap).toBe(BROADCAST_RECIPIENT_CAP);
  });

  it('rejects unknown user IDs', async () => {
    const { resolver } = createResolver({ users: [{ id: 'known', status: 'ACTIVE' }] });

    await expect(
      resolver.validateAudienceUserIds(['known', 'missing']),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('rejects ineligible users', async () => {
    const { resolver } = createResolver({
      users: [{ id: 'suspended', status: 'SUSPENDED' }],
    });

    await expect(resolver.validateAudienceUserIds(['suspended'])).rejects.toMatchObject({
      response: expect.objectContaining({ code: 'BROADCAST_INELIGIBLE_USERS' }),
    });
  });
});
