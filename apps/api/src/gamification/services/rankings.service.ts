import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { Role } from '../../prisma-client';
import { ReportsUploadService } from '../../reports/services/reports-upload.service';
import { getSkopjeWeekBoundsUtc } from '../util/week-skopje';
import {
  projectLeaderboardIdentity,
  resolveActorIdentity,
} from '../../common/projections/public-identity.projection';

/** Weekly totals: sum of positive `PointTransaction.delta` in the Skopje week, citizens (`USER`) only. */

export type WeeklyLeaderboardEntry = {
  rank: number;
  userId?: string;
  displayName: string;
  avatarUrl?: string | null;
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

export type AdminWeeklyLeaderboardEntry = {
  rank: number;
  userId: string;
  displayName: string;
  email: string;
  weeklyPoints: number;
  showOnLeaderboard: boolean;
};

export type AdminWeeklyLeaderboardResult = {
  weekStartsAt: string;
  weekEndsAt: string;
  entries: AdminWeeklyLeaderboardEntry[];
};

@Injectable()
export class RankingsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly reportsUpload: ReportsUploadService,
  ) {}

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
      Array<{
        userId: string;
        pts: number;
        firstName: string;
        lastName: string;
        showOnLeaderboard: boolean;
        avatarObjectKey: string | null;
        status: import('../../prisma-client').UserStatus;
      }>
    >`
      SELECT pt."userId",
             SUM(pt.delta)::int AS pts,
             u."firstName",
             u."lastName",
             u."showOnLeaderboard",
             u."avatarObjectKey",
             u.status
      FROM "PointTransaction" pt
      INNER JOIN "User" u ON u.id = pt."userId"
      WHERE pt."createdAt" >= ${bounds.weekStartsAt}
        AND pt."createdAt" <= ${bounds.weekEndsAt}
        AND pt.delta > 0
        AND u.role = 'USER'::"Role"
      GROUP BY pt."userId", u."firstName", u."lastName", u."showOnLeaderboard", u."avatarObjectKey", u.status
      HAVING SUM(pt.delta) > 0
      ORDER BY pts DESC
      LIMIT ${capped}
    `;

    const avatarKeys = new Set<string>();
    for (const row of rows) {
      if (row.showOnLeaderboard && row.avatarObjectKey) {
        avatarKeys.add(row.avatarObjectKey);
      }
    }
    const avatarUrlByKey = new Map<string, string | null>();
    await Promise.all(
      [...avatarKeys].map(async (key) => {
        avatarUrlByKey.set(key, await this.reportsUpload.signPrivateObjectKey(key));
      }),
    );

    const entries: WeeklyLeaderboardEntry[] = rows.map((row, index) => {
      const isCurrentUser = row.userId === currentUserId;
      const identity = projectLeaderboardIdentity(
        {
          id: row.userId,
          firstName: row.firstName,
          lastName: row.lastName,
          showOnLeaderboard: row.showOnLeaderboard,
          status: row.status,
        },
        currentUserId,
      );
      const avatarKey =
        row.showOnLeaderboard && row.avatarObjectKey ? row.avatarObjectKey : null;
      const avatarUrl =
        avatarKey != null ? (avatarUrlByKey.get(avatarKey) ?? null) : null;
      return {
        rank: index + 1,
        ...(identity.userId ? { userId: identity.userId } : {}),
        displayName: identity.displayLabel,
        avatarUrl,
        weeklyPoints: row.pts,
        isCurrentUser,
      };
    });

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

  async getAdminWeeklyLeaderboard(limit: number, now: Date = new Date()): Promise<AdminWeeklyLeaderboardResult> {
    const bounds = getSkopjeWeekBoundsUtc(now);
    const capped = Math.min(100, Math.max(1, Math.floor(limit)));

    const rows = await this.prisma.$queryRaw<
      Array<{
        userId: string;
        pts: number;
        firstName: string;
        lastName: string;
        email: string;
        showOnLeaderboard: boolean;
        status: import('../../prisma-client').UserStatus;
      }>
    >`
      SELECT pt."userId",
             SUM(pt.delta)::int AS pts,
             u."firstName",
             u."lastName",
             u."email",
             u."showOnLeaderboard",
             u.status
      FROM "PointTransaction" pt
      INNER JOIN "User" u ON u.id = pt."userId"
      WHERE pt."createdAt" >= ${bounds.weekStartsAt}
        AND pt."createdAt" <= ${bounds.weekEndsAt}
        AND pt.delta > 0
        AND u.role = 'USER'::"Role"
      GROUP BY pt."userId", u."firstName", u."lastName", u."email", u."showOnLeaderboard", u.status
      HAVING SUM(pt.delta) > 0
      ORDER BY pts DESC
      LIMIT ${capped}
    `;

    const entries: AdminWeeklyLeaderboardEntry[] = rows.map((row, index) => {
      const identity = resolveActorIdentity(
        {
          firstName: row.firstName,
          lastName: row.lastName,
          status: row.status,
        },
        { actorUserId: row.userId },
      );
      return {
        rank: index + 1,
        userId: row.userId,
        displayName: identity.displayName ?? 'Anonymous',
        email: row.email,
        weeklyPoints: row.pts,
        showOnLeaderboard: row.showOnLeaderboard,
      };
    });

    return {
      weekStartsAt: bounds.weekStartsAtIso,
      weekEndsAt: bounds.weekEndsAtIso,
      entries,
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
