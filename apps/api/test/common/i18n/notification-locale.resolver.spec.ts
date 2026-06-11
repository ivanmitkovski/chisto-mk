/// <reference types="jest" />
import { userLocalesByUserId } from '../../../src/common/i18n/notification-locale.resolver';
import type { PrismaService } from '../../../src/prisma/prisma.service';

function mockPrisma(users: Array<{ id: string; locale: string | null }>, tokens: Array<{ userId: string; locale: string | null; lastSeenAt: Date }>) {
  return {
    user: {
      findMany: jest.fn(async ({ where }: { where: { id: { in: string[] } } }) =>
        users.filter((u) => where.id.in.includes(u.id)),
      ),
    },
    userDeviceToken: {
      findMany: jest.fn(async ({ where }: { where: { userId: { in: string[] } } }) =>
        tokens
          .filter((t) => where.userId.in.includes(t.userId))
          .sort((a, b) => b.lastSeenAt.getTime() - a.lastSeenAt.getTime()),
      ),
    },
  } as unknown as PrismaService;
}

describe('userLocalesByUserId', () => {
  it('prefers User.locale over device token', async () => {
    const prisma = mockPrisma(
      [{ id: 'u1', locale: 'sq' }],
      [{ userId: 'u1', locale: 'en', lastSeenAt: new Date() }],
    );
    const map = await userLocalesByUserId(prisma, ['u1']);
    expect(map.get('u1')).toBe('sq');
  });

  it('falls back to most recent device token locale', async () => {
    const prisma = mockPrisma(
      [{ id: 'u1', locale: null }],
      [
        { userId: 'u1', locale: 'en', lastSeenAt: new Date('2026-01-02') },
        { userId: 'u1', locale: 'mk', lastSeenAt: new Date('2026-01-01') },
      ],
    );
    const map = await userLocalesByUserId(prisma, ['u1']);
    expect(map.get('u1')).toBe('en');
  });

  it('defaults to mk when no locale sources exist', async () => {
    const prisma = mockPrisma([], []);
    const map = await userLocalesByUserId(prisma, ['unknown']);
    expect(map.get('unknown')).toBe('mk');
  });

  it('normalizes sq from device token', async () => {
    const prisma = mockPrisma(
      [{ id: 'u1', locale: null }],
      [{ userId: 'u1', locale: 'sq', lastSeenAt: new Date() }],
    );
    const map = await userLocalesByUserId(prisma, ['u1']);
    expect(map.get('u1')).toBe('sq');
  });
});
