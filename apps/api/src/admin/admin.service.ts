import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';

export type AdminOverviewStats = {
  reportsByStatus: Record<string, number>;
  sitesByStatus: Record<string, number>;
  cleanupEvents: {
    upcoming: number;
    completed: number;
  };
};

export type AdminSecuritySession = {
  id: string;
  device: string;
  location: string;
  ipAddress: string;
  lastActiveLabel: string;
  isCurrent: boolean;
};

export type AdminSecurityActivityTone = 'success' | 'warning' | 'info';

export type AdminSecurityActivityEvent = {
  id: string;
  title: string;
  detail: string;
  occurredAtLabel: string;
  tone: AdminSecurityActivityTone;
  icon: string;
};

export type AdminSecurityOverview = {
  sessions: AdminSecuritySession[];
  activity: AdminSecurityActivityEvent[];
};

@Injectable()
export class AdminService {
  constructor(private readonly prisma: PrismaService) {}

  async getOverview(): Promise<AdminOverviewStats> {
    const [reportGroups, siteGroups, upcomingEvents, completedEvents] = await this.prisma.$transaction([
      this.prisma.report.groupBy({
        by: ['status'],
        orderBy: {
          status: 'asc',
        },
        _count: { _all: true },
      }),
      this.prisma.site.groupBy({
        by: ['status'],
        orderBy: {
          status: 'asc',
        },
        _count: { _all: true },
      }),
      this.prisma.cleanupEvent.count({
        where: {
          completedAt: null,
        },
      }),
      this.prisma.cleanupEvent.count({
        where: {
          completedAt: {
            not: null,
          },
        },
      }),
    ]);

    const reportsByStatus: Record<string, number> = {};
    for (const group of reportGroups) {
      const countAll =
        typeof group._count === 'object' && group._count && '_all' in group._count && typeof group._count._all === 'number'
          ? group._count._all
          : 0;
      reportsByStatus[group.status] = countAll;
    }

    const sitesByStatus: Record<string, number> = {};
    for (const group of siteGroups) {
      const countAll =
        typeof group._count === 'object' && group._count && '_all' in group._count && typeof group._count._all === 'number'
          ? group._count._all
          : 0;
      sitesByStatus[group.status] = countAll;
    }

    return {
      reportsByStatus,
      sitesByStatus,
      cleanupEvents: {
        upcoming: upcomingEvents,
        completed: completedEvents,
      },
    };
  }

  async getSecurityOverview(admin: AuthenticatedUser): Promise<AdminSecurityOverview> {
    // No session or audit storage yet; return empty. Wire to real tables when available.
    void admin;
    return {
      sessions: [],
      activity: [],
    };
  }
}

