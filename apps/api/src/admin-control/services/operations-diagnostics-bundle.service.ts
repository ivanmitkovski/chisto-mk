import { Injectable } from '@nestjs/common';
import { ObservabilityStore } from '../../observability/observability.store';
import { PrismaService } from '../../prisma/prisma.service';
import { EmailPipelineHealthService } from '../../email/services/email-pipeline-health.service';
import { PushDiagnosticsService } from '../../notifications/services/push-diagnostics.service';
import { PushPipelineHealthService } from '../../notifications/services/push-pipeline-health.service';
import { OperationsStatusService } from './operations-status.service';

@Injectable()
export class OperationsDiagnosticsBundleService {
  constructor(
    private readonly operationsStatus: OperationsStatusService,
    private readonly pushDiagnostics: PushDiagnosticsService,
    private readonly pushHealth: PushPipelineHealthService,
    private readonly emailHealth: EmailPipelineHealthService,
    private readonly prisma: PrismaService,
  ) {}

  async getBundle() {
    const [systemInfo, readiness, workers, pushDiagnostics, pushHealth, emailHealth, feedDiagnostics] =
      await Promise.all([
        Promise.resolve(this.operationsStatus.getSystemInfo()),
        this.operationsStatus.getReadiness(),
        Promise.resolve(this.operationsStatus.getWorkers()),
        this.pushDiagnostics.getDiagnostics(),
        this.pushHealth.getHealthSnapshot(),
        this.emailHealth.getHealthSnapshot(),
        this.getFeedDiagnostics(),
      ]);

    return {
      systemInfo,
      readiness,
      workers,
      pushDiagnostics,
      pushHealth,
      emailHealth,
      feedDiagnostics,
      metrics: this.operationsStatus.getMetricsSnapshot(),
      capturedAt: new Date().toISOString(),
    };
  }

  private async getFeedDiagnostics() {
    const snap = ObservabilityStore.snapshot();
    const reasonCodes = Object.entries(snap.feedReasonCodeCounts ?? {})
      .map(([code, count]) => ({ code, count }))
      .sort((a, b) => b.count - a.count)
      .slice(0, 8);

    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
    const recentIntegrityDemotions = await this.prisma.auditLog.count({
      where: {
        action: { contains: 'INTEGRITY_DAMPENED' },
        createdAt: { gte: sevenDaysAgo },
      },
    });

    return {
      reasonCodes,
      recentIntegrityDemotions,
      paginationContinuityIssues: snap.feedPaginationContinuityIssues ?? 0,
      rankerMode: snap.feedV2RankerMode ?? 'unknown',
    };
  }
}
