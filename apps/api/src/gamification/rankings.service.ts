import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { Role } from '../prisma-client';
import { getSkopjeWeekBoundsUtc } from './week-skopje';

/** Weekly totals: sum of positive `PointTransaction.delta` in the Skopje week, citizens (`USER`) only. */

export type WeeklyLeaderboardEntry = {
  rank: number;
  userId: string;
  displayName: string;
  weeklyPoints: number;
  isCurrentUser: boolean;
};

export type WeeklyLeaderboardResult = {
  weekStartsAt: string;
  weekEndsAt: string;
  entries: WeeklyLeaderboardEntry[];
  myRank: number | null;
  myWeeklyPoints: number;
};

export type UserWeeklySummary = {
  weeklyPoints: number;
  weeklyRank: number | null;
  weekStartsAt: string;
  weekEndsAt: string;
};

@Injectable()
export class RankingsService {
  constructor(private readonly prisma: PrismaService) {}

  async getUserWeeklySummary(userId: string, now: Date = new Date()): Promise<UserWeeklySummary> {
    const bounds = getSkopjeWeekBoundsUtc(now);
    const weeklyPoints = await this.sumWeeklyPointsForUser(userId, bounds.weekStartsAt, bounds.weekEndsAt);

    if (weeklyPoints <= 0) {
      return {
        weeklyPoints: 0,
        weeklyRank: null,
        weekStartsAt: bounds.weekStartsAtIso,
        weekEndsAt: bounds.weekEndsAtIso,
      };
    }

    const higherCount = await this.countUsersWithHigherWeeklyPoints(
      weeklyPoints,
      bounds.weekStartsAt,
      bounds.weekEndsAt,
    );

    return {
      weeklyPoints,
      weeklyRank: higherCount + 1,
      weekStartsAt: bounds.weekStartsAtIso,
      weekEndsAt: bounds.weekEndsAtIso,
    };
  }

  async getWeeklyLeaderboard(currentUserId: string, limit: number, now: Date = new Date()): Promise<WeeklyLeaderboardResult> {
    const bounds = getSkopjeWeekBoundsUtc(now);
    const capped = Math.min(100, Math.max(1, Math.floor(limit)));

    const rows = await this.prisma.$queryRaw<
      Array<{ userId: string; pts: number; firstName: string; lastName: string }>
    >`
      SELECT pt."userId",
             SUM(pt.delta)::int AS pts,
             u."firstName",
             u."lastName"
      FROM "PointTransaction" pt
      INNER JOIN "User" u ON u.id = pt."userId"
      WHERE pt."createdAt" >= ${bounds.weekStartsAt}
        AND pt."createdAt" <= ${bounds.weekEndsAt}
        AND pt.delta > 0
        AND u.role = 'USER'::"Role"
      GROUP BY pt."userId", u."firstName", u."lastName"
      HAVING SUM(pt.delta) > 0
      ORDER BY pts DESC
      LIMIT ${capped}
    `;

    const entries: WeeklyLeaderboardEntry[] = rows.map((row, index) => ({
      rank: index + 1,
      userId: row.userId,
      displayName: `${row.firstName} ${row.lastName}`.trim(),
      weeklyPoints: row.pts,
      isCurrentUser: row.userId === currentUserId,
    }));

    const myWeeklyPoints = await this.sumWeeklyPointsForUser(currentUserId, bounds.weekStartsAt, bounds.weekEndsAt);
    let myRank: number | null = null;
    if (myWeeklyPoints > 0) {
      myRank = (await this.countUsersWithHigherWeeklyPoints(myWeeklyPoints, bounds.weekStartsAt, bounds.weekEndsAt)) + 1;
    }

    return {
      weekStartsAt: bounds.weekStartsAtIso,
      weekEndsAt: bounds.weekEndsAtIso,
      entries,
      myRank,
      myWeeklyPoints,
    };
  }

  private async sumWeeklyPointsForUser(
    userId: string,
    weekStartsAt: Date,
    weekEndsAt: Date,
  ): Promise<number> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { role: true },
    });
    if (user?.role !== Role.USER) {
      return 0;
    }

    const agg = await this.prisma.pointTransaction.aggregate({
      where: {
        userId,
        createdAt: { gte: weekStartsAt, lte: weekEndsAt },
        delta: { gt: 0 },
      },
      _sum: { delta: true },
    });
    return agg._sum.delta ?? 0;
  }

  private async countUsersWithHigherWeeklyPoints(
    weeklyPoints: number,
    weekStartsAt: Date,
    weekEndsAt: Date,
  ): Promise<number> {
    const result = await this.prisma.$queryRaw<Array<{ count: bigint }>>`
      WITH sums AS (
        SELECT pt."userId", SUM(pt.delta)::int AS pts
        FROM "PointTransaction" pt
        INNER JOIN "User" u ON u.id = pt."userId"
        WHERE pt."createdAt" >= ${weekStartsAt}
          AND pt."createdAt" <= ${weekEndsAt}
          AND pt.delta > 0
          AND u.role = 'USER'::"Role"
        GROUP BY pt."userId"
        HAVING SUM(pt.delta) > 0
      )
      SELECT COUNT(*)::bigint AS count FROM sums WHERE pts > ${weeklyPoints}
    `;
    return Number(result[0]?.count ?? 0n);
  }
}
