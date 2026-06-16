import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { AdminAlertMetric, AdminAlertComparator } from '../../prisma-client';
import { PrismaService } from '../../prisma/prisma.service';
import { ObservabilityStore } from '../../observability/observability.store';
import { ActiveUsersPresenceService } from './active-users-presence.service';
import { ActiveUsersRealtimeService } from './active-users-realtime.service';

const COOLDOWN_MS = 5 * 60_000;

@Injectable()
export class AdminAlertEvaluationService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(AdminAlertEvaluationService.name);
  private timer: ReturnType<typeof setInterval> | null = null;
  private recentConcurrent: number[] = [];

  constructor(
    private readonly prisma: PrismaService,
    private readonly presence: ActiveUsersPresenceService,
    private readonly realtime: ActiveUsersRealtimeService,
  ) {}

  onModuleInit(): void {
    if (process.env.ADMIN_ALERTS_ENABLED === 'false') return;
    this.timer = setInterval(() => {
      void this.evaluate().catch((err: unknown) => {
        this.logger.error('Admin alert evaluation tick failed', err);
      });
    }, 30_000);
  }

  onModuleDestroy(): void {
    if (this.timer) clearInterval(this.timer);
  }

  private async evaluate(): Promise<void> {
    const rules = await this.prisma.adminAlertRule.findMany({ where: { enabled: true } });
    if (rules.length === 0) return;

    const concurrent = await this.presence.countDistinctActive();
    this.recentConcurrent.push(concurrent);
    if (this.recentConcurrent.length > 20) this.recentConcurrent.shift();

    const snap = ObservabilityStore.snapshot();
    const errorRate =
      snap.requestsTotal > 0 ? snap.requestsFailed / snap.requestsTotal : 0;
    const reportActivity = snap.reportsSubmitSuccess + snap.reportsSubmitError;
    const apiDegradation = snap.p95Ms;

    for (const rule of rules) {
      if (rule.lastTriggeredAt && Date.now() - rule.lastTriggeredAt.getTime() < COOLDOWN_MS) {
        continue;
      }
      const value = this.metricValue(rule.metric, {
        concurrent,
        errorRate,
        reportActivity,
        apiDegradation,
      });
      if (value == null) continue;
      const breached = this.compare(value, rule.threshold, rule.comparator);
      if (!breached) continue;

      await this.prisma.adminAlertRule.update({
        where: { id: rule.id },
        data: { lastTriggeredAt: new Date() },
      });
      const message = `${rule.metric} ${rule.comparator} ${rule.threshold} (current: ${value.toFixed(2)})`;
      this.realtime.publishAlertTriggered({
        type: 'alert_triggered',
        ruleId: rule.id,
        metric: rule.metric,
        value,
        threshold: rule.threshold,
        message,
      });
      this.logger.warn(`Admin alert triggered: ${message}`);
    }
  }

  private metricValue(
    metric: AdminAlertMetric,
    ctx: {
      concurrent: number;
      errorRate: number;
      reportActivity: number;
      apiDegradation: number;
    },
  ): number | null {
    switch (metric) {
      case AdminAlertMetric.CONCURRENT:
        return ctx.concurrent;
      case AdminAlertMetric.TRAFFIC_SPIKE: {
        if (this.recentConcurrent.length < 3) return null;
        const avg =
          this.recentConcurrent.slice(0, -1).reduce((a, b) => a + b, 0) /
          (this.recentConcurrent.length - 1);
        return avg > 0 ? ctx.concurrent / avg : ctx.concurrent;
      }
      case AdminAlertMetric.ERROR_RATE:
        return ctx.errorRate;
      case AdminAlertMetric.REPORT_ACTIVITY:
        return ctx.reportActivity;
      case AdminAlertMetric.API_DEGRADATION:
        return ctx.apiDegradation;
      default:
        return null;
    }
  }

  private compare(value: number, threshold: number, comparator: AdminAlertComparator): boolean {
    return comparator === AdminAlertComparator.GTE ? value >= threshold : value > threshold;
  }
}
