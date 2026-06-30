import { Injectable, Optional } from '@nestjs/common';
import { CircuitState } from '../../common/resilience/circuit-breaker';
import { ObservabilityStore } from '../../observability/observability.store';
import { WorkerHeartbeatRegistry } from '../../observability/worker-heartbeat.registry';
import { PrismaService } from '../../prisma/prisma.service';
import { FcmPushService } from './fcm-push.service';
import { PushDeliveryWorkerService } from './push-delivery-worker.service';

const PUSH_WORKER_NAME = 'push-delivery';
const QUEUE_DEPTH_WARN = 25;
const QUEUE_DEPTH_CRITICAL = 100;

export type PushPipelineHealthSnapshot = {
  status: 'ok' | 'degraded' | 'disabled';
  fcmEnabled: boolean;
  fcmReady: boolean;
  projectId: string | null;
  credentialStatus: string;
  credentialParseError: string | null;
  worker: {
    expected: boolean;
    running: boolean;
    stale: boolean;
    lastError?: string;
  };
  outbox: {
    pending: number;
    leased: number;
    deadLetter: number;
    oldestPendingAgeSec: number | null;
  };
  circuitBreaker: { state: 'closed' | 'open' | 'half_open' };
  pgListener: { enabled: boolean; connected: boolean };
  dispatchSkips: {
    fcmNotReady: number;
    noTokens: number;
    writerNull: number;
  };
  alerts: string[];
};

@Injectable()
export class PushPipelineHealthService {
  constructor(
    private readonly fcm: FcmPushService,
    private readonly prisma: PrismaService,
    @Optional() private readonly pushWorker: PushDeliveryWorkerService | null,
  ) {}

  async getHealthSnapshot(): Promise<PushPipelineHealthSnapshot> {
    const fcmEnabled = this.fcm.isEnabled();
    const fcmReady = this.fcm.isReady();
    const credential = this.fcm.getCredentialValidation();
    const metrics = ObservabilityStore.snapshot();
    const workerSnap = WorkerHeartbeatRegistry.snapshot().find((w) => w.name === PUSH_WORKER_NAME);
    const workerExpected = fcmEnabled;
    const workerRunning = workerSnap?.running ?? false;
    const workerStale = workerExpected && (workerSnap == null || workerSnap.stale);
    const pgListener = this.pushWorker?.getPgListenerStatus() ?? {
      enabled: false,
      connected: false,
    };
    const circuitState = this.fcm.getCircuitBreakerState();

    const pendingWhere = {
      deliveredAt: null,
      failedPermanently: false,
    } as const;

    const [pending, leased, deadLetter, oldestPending] = await Promise.all([
      this.prisma.notificationOutbox.count({ where: pendingWhere }),
      this.prisma.notificationOutbox.count({
        where: {
          ...pendingWhere,
          processingAt: { not: null },
        },
      }),
      this.prisma.notificationOutbox.count({
        where: { failedPermanently: true },
      }),
      this.prisma.notificationOutbox.findFirst({
        where: pendingWhere,
        orderBy: { createdAt: 'asc' },
        select: { createdAt: true },
      }),
    ]);

    const oldestPendingAgeSec =
      oldestPending != null
        ? Math.max(0, Math.floor((Date.now() - oldestPending.createdAt.getTime()) / 1000))
        : null;

    const alerts: string[] = [];
    if (!fcmEnabled) {
      return {
        status: 'disabled',
        fcmEnabled,
        fcmReady,
        projectId: this.fcm.getProjectId() ?? credential.projectId,
        credentialStatus: credential.status,
        credentialParseError: credential.parseError,
        worker: {
          expected: workerExpected,
          running: workerRunning,
          stale: workerStale,
          ...(workerSnap?.lastError ? { lastError: workerSnap.lastError } : {}),
        },
        outbox: { pending, leased, deadLetter, oldestPendingAgeSec },
        circuitBreaker: { state: this.mapCircuitState(circuitState) },
        pgListener,
        dispatchSkips: {
          fcmNotReady: metrics.pushDispatchSkippedFcmNotReady,
          noTokens: metrics.pushDispatchSkippedNoTokens,
          writerNull: metrics.pushDispatchSkippedWriterNull,
        },
        alerts,
      };
    }

    if (!fcmReady) {
      alerts.push('fcm_enabled_not_ready');
    }
    if (credential.status !== 'valid' && credential.status !== 'missing') {
      alerts.push(`firebase_credential_${credential.status}`);
    }
    if (workerStale) {
      alerts.push('push_worker_stale');
    }
    if (pending >= QUEUE_DEPTH_CRITICAL) {
      alerts.push(`queue_depth_critical:${pending}`);
    } else if (pending >= QUEUE_DEPTH_WARN) {
      alerts.push(`queue_depth_high:${pending}`);
    }
    if (deadLetter > 0) {
      alerts.push(`dead_letter_total:${deadLetter}`);
    }
    if (circuitState === CircuitState.OPEN) {
      alerts.push('fcm_circuit_open');
    }
    if (
      metrics.pushDispatchSkippedFcmNotReady > 0 ||
      metrics.pushDispatchSkippedNoTokens > 0
    ) {
      alerts.push('push_dispatch_skipped');
    }

    const status = alerts.some((a) =>
      [
        'fcm_enabled_not_ready',
        'push_worker_stale',
        'fcm_circuit_open',
        'firebase_credential_invalid_json',
        'firebase_credential_invalid_structure',
      ].some((critical) => a.startsWith(critical)) ||
      a.startsWith('queue_depth_critical'),
    )
      ? 'degraded'
      : alerts.length > 0
        ? 'degraded'
        : 'ok';

    return {
      status,
      fcmEnabled,
      fcmReady,
      projectId: this.fcm.getProjectId() ?? credential.projectId,
      credentialStatus: credential.status,
      credentialParseError: credential.parseError,
      worker: {
        expected: workerExpected,
        running: workerRunning,
        stale: workerStale,
        ...(workerSnap?.lastError ? { lastError: workerSnap.lastError } : {}),
      },
      outbox: { pending, leased, deadLetter, oldestPendingAgeSec },
      circuitBreaker: { state: this.mapCircuitState(circuitState) },
      pgListener,
      dispatchSkips: {
        fcmNotReady: metrics.pushDispatchSkippedFcmNotReady,
        noTokens: metrics.pushDispatchSkippedNoTokens,
        writerNull: metrics.pushDispatchSkippedWriterNull,
      },
      alerts,
    };
  }

  private mapCircuitState(state: CircuitState): 'closed' | 'open' | 'half_open' {
    if (state === CircuitState.OPEN) return 'open';
    if (state === CircuitState.HALF_OPEN) return 'half_open';
    return 'closed';
  }
}
