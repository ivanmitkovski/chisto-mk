/// <reference types="jest" />

import { Role } from '../../src/prisma-client';
import { RankingsService } from '../../src/gamification/rankings.service';
import type { PrismaService } from '../../src/prisma/prisma.service';

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
    const service = new RankingsService(prisma);
    const now = new Date('2026-04-22T12:00:00.000Z');

    const summary = await service.getUserWeeklySummary('user-1', now);

    expect(summary.weeklyPoints).toBe(0);
    expect(summary.weeklyRank).toBeNull();
    expect(summary.weekStartsAt).toMatch(/^\d{4}-\d{2}-\d{2}T/);
    expect(summary.weekEndsAt).toMatch(/^\d{4}-\d{2}-\d{2}T/);
  });
});
