/// <reference types="jest" />

import { Role, UserStatus } from '../../src/prisma-client';
import { RankingsService } from '../../src/gamification/services/rankings.service';
import type { PrismaService } from '../../src/prisma/prisma.service';
import type { ReportsUploadService } from '../../src/reports/services/reports-upload.service';

function makeService(
  prisma: PrismaService,
  reportsUpload?: Partial<ReportsUploadService>,
): RankingsService {
  const upload = {
    signPrivateObjectKey: jest.fn().mockResolvedValue(null),
    ...reportsUpload,
  } as unknown as ReportsUploadService;
  return new RankingsService(prisma, upload);
}

describe('RankingsService', () => {
  it('getUserWeeklySummary returns zeros when user has no positive weekly points', async () => {
    const prisma = {
      user: {
        findUnique: jest.fn().mockResolvedValue({ role: Role.USER }),
      },
      pointTransaction: {
        aggregate: jest.fn().mockResolvedValue({ _sum: { delta: null } }),
      },
    } as unknown as PrismaService;
    const service = makeService(prisma);
    const now = new Date('2026-04-22T12:00:00.000Z');

    const summary = await service.getUserWeeklySummary('user-1', now);

    expect(summary.weeklyPoints).toBe(0);
    expect(summary.weeklyRank).toBeNull();
    expect(summary.weekStartsAt).toMatch(/^\d{4}-\d{2}-\d{2}T/);
    expect(summary.weekEndsAt).toMatch(/^\d{4}-\d{2}-\d{2}T/);
  });

  it('getWeeklyLeaderboard returns full names and signed avatars for opted-in users', async () => {
    const signPrivateObjectKey = jest
      .fn()
      .mockResolvedValue('https://signed.example/avatar.jpg');
    const prisma = {
      user: {
        findUnique: jest.fn().mockResolvedValue({ role: Role.USER }),
      },
      $queryRaw: jest
        .fn()
        .mockResolvedValueOnce([
          {
            userId: 'user-public',
            pts: 55,
            firstName: 'Ivan',
            lastName: 'Mitkovski',
            showOnLeaderboard: true,
            avatarObjectKey: 'avatars/user-public.jpg',
            status: UserStatus.ACTIVE,
          },
          {
            userId: 'user-private',
            pts: 35,
            firstName: 'Filip',
            lastName: 'Gjorgiev',
            showOnLeaderboard: false,
            avatarObjectKey: 'avatars/user-private.jpg',
            status: UserStatus.ACTIVE,
          },
        ])
        .mockResolvedValueOnce([{ count: 0n }]),
      pointTransaction: {
        aggregate: jest.fn().mockResolvedValue({ _sum: { delta: 55 } }),
      },
    } as unknown as PrismaService;
    const service = makeService(prisma, { signPrivateObjectKey });
    const now = new Date('2026-06-09T12:00:00.000Z');

    const result = await service.getWeeklyLeaderboard('viewer-1', 50, now);

    expect(result.entries).toHaveLength(2);
    expect(result.entries[0]).toMatchObject({
      rank: 1,
      userId: 'user-public',
      displayName: 'Ivan Mitkovski',
      avatarUrl: 'https://signed.example/avatar.jpg',
      weeklyPoints: 55,
      isCurrentUser: false,
    });
    expect(result.entries[1]).toMatchObject({
      rank: 2,
      displayName: 'Anonymous',
      avatarUrl: null,
      weeklyPoints: 35,
      isCurrentUser: false,
    });
    expect(result.entries[1].userId).toBeUndefined();
    expect(signPrivateObjectKey).toHaveBeenCalledTimes(1);
    expect(signPrivateObjectKey).toHaveBeenCalledWith('avatars/user-public.jpg');
  });
});
