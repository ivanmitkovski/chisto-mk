import { Injectable, Logger } from '@nestjs/common';
import type { AuthenticatedUser } from '../auth/types/authenticated-user.type';
import { AuditService } from '../audit/audit.service';
import { SessionsService } from '../sessions/sessions.service';
import { AdminAggregationQueryService } from './admin-aggregation-query.service';
import { AdminDashboardStatsService } from './admin-dashboard-stats.service';
import type { AdminOverviewStats, AdminSecurityOverview } from './admin-overview.types';

export type {
  AdminOverviewStats,
  AdminSecurityActivityEvent,
  AdminSecurityActivityTone,
  AdminSecuritySession,
  AdminSecurityOverview,
} from './admin-overview.types';

@Injectable()
export class AdminService {
  private static readonly OVERVIEW_CACHE_TTL_MS = 5 * 60 * 1000;

  private readonly logger = new Logger(AdminService.name);
  private overviewCache: { expiresAt: number; data: AdminOverviewStats } | null = null;

  constructor(
    private readonly audit: AuditService,
    private readonly sessions: SessionsService,
    private readonly dashboardStats: AdminDashboardStatsService,
    private readonly aggregationQuery: AdminAggregationQueryService,
  ) {}

  async getOverview(): Promise<AdminOverviewStats> {
    const startedAt = Date.now();
    const nowMs = Date.now();
    if (this.overviewCache && this.overviewCache.expiresAt > nowMs) {
      return this.overviewCache.data;
    }

    const now = new Date();
    const sevenDaysAgo = new Date(now);
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
    const thirtyDaysAgo = new Date(now);
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const raw = await this.dashboardStats.loadRawOverviewBundle(now, sevenDaysAgo, thirtyDaysAgo);
    const payload = this.aggregationQuery.assembleOverviewStats(raw);

    const durationMs = Date.now() - startedAt;
    if (durationMs > 2_000) {
      this.logger.warn(`getOverview completed in ${durationMs}ms`);
    } else {
      this.logger.debug(`getOverview completed in ${durationMs}ms`);
    }

    this.overviewCache = {
      expiresAt: Date.now() + AdminService.OVERVIEW_CACHE_TTL_MS,
      data: payload,
    };
    return payload;
  }

  async getSecurityOverview(admin: AuthenticatedUser): Promise<AdminSecurityOverview> {
    const sessions = await this.sessions.listMine(admin);
    const activity = await this.audit.recentForUser(admin.userId, 20);
    return {
      sessions,
      activity,
    };
  }
}
