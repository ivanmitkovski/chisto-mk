import { Injectable, NotFoundException } from '@nestjs/common';
import { DevicePlatform, UserActivityEventType } from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';
import { ActiveUsersPresenceService } from './active-users-presence.service';
import { ActiveUsersRealtimeService } from './active-users-realtime.service';
import { UserActivityService } from './user-activity.service';
import type { ActiveUsersSummary, PresenceStatus } from '../types/presence.types';

@Injectable()
export class ActiveUsersAdminService {
  constructor(
    private readonly presence: ActiveUsersPresenceService,
    private readonly realtime: ActiveUsersRealtimeService,
    private readonly activity: UserActivityService,
    private readonly prisma: PrismaService,
  ) {}

  async getSummary(): Promise<ActiveUsersSummary> {
    const counts = await this.presence.countByStatus();
    const [peakToday, peakWeek] = await Promise.all([
      this.realtime.getPeakToday(),
      this.realtime.getPeakWeek(),
    ]);
    return {
      currentActive: counts.total,
      online: counts.online,
      away: counts.away,
      offlineUsersEstimate: 0,
      trend5m: await this.realtime.getTrend(5 * 60_000),
      trend15m: await this.realtime.getTrend(15 * 60_000),
      trend1h: await this.realtime.getTrend(60 * 60_000),
      peakToday,
      peakWeek,
      avgConcurrent: await this.realtime.getAvgConcurrent(),
    };
  }

  async listActiveUsers(query: {
    page: number;
    limit: number;
    status?: PresenceStatus;
    platform?: DevicePlatform;
    search?: string;
  }) {
    const skip = (query.page - 1) * query.limit;
    return this.presence.listActiveRows({
      ...(query.status ? { status: query.status } : {}),
      ...(query.platform ? { platform: query.platform } : {}),
      ...(query.search ? { search: query.search } : {}),
      skip,
      take: query.limit,
    });
  }

  async getUserDetails(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        firstName: true,
        lastName: true,
        email: true,
        role: true,
        createdAt: true,
        lastActiveAt: true,
        sessions: {
          where: { revokedAt: null, expiresAt: { gt: new Date() } },
          orderBy: { lastSeenAt: 'desc' },
          take: 5,
          select: {
            id: true,
            deviceId: true,
            deviceInfo: true,
            ipAddress: true,
            platform: true,
            appVersion: true,
            deviceModel: true,
            osVersion: true,
            country: true,
            city: true,
            lastSeenAt: true,
            createdAt: true,
          },
        },
      },
    });
    if (!user) throw new NotFoundException({ code: 'USER_NOT_FOUND', message: 'User not found' });

    const [timeline, sessionsToday] = await Promise.all([
      this.activity.getTimeline(userId, 100),
      this.activity.countSessionsToday(userId),
    ]);

    return {
      user: {
        id: user.id,
        firstName: user.firstName,
        lastName: user.lastName,
        email: user.email,
        role: user.role,
        registeredAt: user.createdAt.toISOString(),
        lastActiveAt: user.lastActiveAt?.toISOString() ?? null,
      },
      sessions: user.sessions.map((s) => ({
        id: s.id,
        deviceId: s.deviceId,
        deviceInfo: s.deviceInfo,
        ipAddress: s.ipAddress,
        platform: s.platform,
        appVersion: s.appVersion,
        deviceModel: s.deviceModel,
        osVersion: s.osVersion,
        country: s.country,
        city: s.city,
        lastSeenAt: s.lastSeenAt?.toISOString() ?? null,
        startedAt: s.createdAt.toISOString(),
      })),
      sessionsToday,
      timeline,
    };
  }

  getActivityFeed(query: {
    page: number;
    limit: number;
    type?: UserActivityEventType;
    search?: string;
  }) {
    return this.activity.getActivityFeed(query);
  }

  async getEngagementAnalytics() {
    const startOfToday = this.startOfUtcDay(new Date());
    const thirtyDaysAgo = this.startOfUtcDay(new Date());
    thirtyDaysAgo.setUTCDate(thirtyDaysAgo.getUTCDate() - 29);

    const [
      dau,
      wau,
      mau,
      sessionsToday,
      reportsToday,
      dailyDauRows,
      rollupStats,
      avgSessionRow,
    ] = await Promise.all([
      this.countDistinctActiveUsersSince(startOfToday),
      this.countDistinctActiveUsersSince(this.daysBeforeToday(6)),
      this.countDistinctActiveUsersSince(this.daysBeforeToday(29)),
      this.prisma.userActivityEvent.count({
        where: { type: { in: ['LOGIN', 'APP_OPENED'] }, occurredAt: { gte: startOfToday } },
      }),
      this.prisma.userActivityEvent.count({
        where: { type: 'REPORT_SUBMITTED', occurredAt: { gte: startOfToday } },
      }),
      this.getDailyDistinctActiveUsersSince(thirtyDaysAgo),
      this.prisma.dailyActiveStat.findMany({
        where: { date: { gte: thirtyDaysAgo } },
        orderBy: { date: 'desc' },
      }),
      this.prisma.$queryRaw<Array<{ avg_minutes: number | null }>>`
        SELECT AVG(EXTRACT(EPOCH FROM ("lastSeenAt" - "createdAt")) / 60.0)::float AS avg_minutes
        FROM "UserSession"
        WHERE "lastSeenAt" IS NOT NULL
          AND "lastSeenAt" >= ${startOfToday}
      `,
    ]);

    const dauByDate = new Map(dailyDauRows.map((row) => [row.date, Number(row.dau)]));
    const rollupByDate = new Map(
      rollupStats.map((row) => [this.formatDateKey(row.date), row]),
    );

    const history: Array<{
      date: string;
      dau: number;
      wau: number;
      mau: number;
      peakConcurrent: number;
      avgConcurrent: number;
    }> = [];

    for (let offset = 29; offset >= 0; offset -= 1) {
      const day = this.startOfUtcDay(new Date());
      day.setUTCDate(day.getUTCDate() - offset);
      const date = this.formatDateKey(day);
      const rollup = rollupByDate.get(date);
      history.push({
        date,
        dau: dauByDate.get(date) ?? rollup?.dau ?? 0,
        wau: rollup?.wau ?? 0,
        mau: rollup?.mau ?? 0,
        peakConcurrent: rollup?.peakConcurrent ?? 0,
        avgConcurrent: rollup?.avgConcurrent ?? 0,
      });
    }

    history.reverse();

    const avgSessionDurationMinutes =
      avgSessionRow[0]?.avg_minutes != null
        ? Math.round(avgSessionRow[0].avg_minutes * 10) / 10
        : 0;

    return {
      dau,
      wau,
      mau,
      dauMauRatio: mau > 0 ? Math.round((dau / mau) * 1000) / 1000 : 0,
      avgSessionDurationMinutes,
      sessionsPerUser: dau > 0 ? Math.round((sessionsToday / dau) * 100) / 100 : 0,
      reportsSubmittedToday: reportsToday,
      history,
    };
  }

  private startOfUtcDay(date: Date): Date {
    return new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));
  }

  private formatDateKey(date: Date): string {
    return date.toISOString().slice(0, 10);
  }

  private daysBeforeToday(days: number): Date {
    const start = this.startOfUtcDay(new Date());
    start.setUTCDate(start.getUTCDate() - days);
    return start;
  }

  private async countDistinctActiveUsersSince(since: Date): Promise<number> {
    const [row] = await this.prisma.$queryRaw<Array<{ count: bigint }>>`
      SELECT COUNT(DISTINCT "userId")::bigint AS count
      FROM "UserActivityEvent"
      WHERE "occurredAt" >= ${since}
    `;
    return Number(row?.count ?? 0);
  }

  private async getDailyDistinctActiveUsersSince(
    since: Date,
  ): Promise<Array<{ date: string; dau: bigint }>> {
    return this.prisma.$queryRaw<Array<{ date: string; dau: bigint }>>`
      SELECT ("occurredAt"::date)::text AS date, COUNT(DISTINCT "userId")::bigint AS dau
      FROM "UserActivityEvent"
      WHERE "occurredAt" >= ${since}
      GROUP BY "occurredAt"::date
      ORDER BY date ASC
    `;
  }

  async getRealtimeAnalytics() {
    const start = new Date();
    start.setHours(0, 0, 0, 0);
    const [concurrent, reportsToday, registrationsToday, activeDrafts] = await Promise.all([
      this.presence.countDistinctActive(),
      this.prisma.userActivityEvent.count({
        where: { type: 'REPORT_SUBMITTED', occurredAt: { gte: start } },
      }),
      this.prisma.user.count({ where: { createdAt: { gte: start } } }),
      this.prisma.report.count({
        where: { status: 'NEW', createdAt: { gte: new Date(Date.now() - 24 * 60 * 60_000) } },
      }),
    ]);
    return {
      concurrent,
      activeReportDrafts: activeDrafts,
      activeCleanupParticipants: 0,
      reportsSubmittedToday: reportsToday,
      registrationsToday,
    };
  }

  getGeoClusters() {
    return this.presence.getGeoClusters();
  }
}
