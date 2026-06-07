import type { HealthStatus } from '@/components/ui';
import type { OperationsSnapshot, PanelState } from '../data/operations-adapter';
import { OPS_THRESHOLDS } from '../config';

export type OperationsPanelKey = keyof OperationsSnapshot;

export type SystemHealthSummary = {
  status: HealthStatus;
  okCount: number;
  warnCount: number;
  criticalCount: number;
  unknownCount: number;
};

function panelFetchHealth(panel: PanelState<unknown>): HealthStatus {
  if (panel.status === 'forbidden') return 'unknown';
  if (panel.status === 'error') return 'critical';
  return 'ok';
}

export function derivePanelHealth(key: OperationsPanelKey, panel: PanelState<unknown>): HealthStatus {
  const fetchHealth = panelFetchHealth(panel);
  if (fetchHealth !== 'ok') return fetchHealth;
  if (panel.status !== 'ok') return 'unknown';

  switch (key) {
    case 'pushStats': {
      const data = panel.data as OperationsSnapshot['pushStats'] extends PanelState<infer T> ? T : never;
      if (data.deadLetterCount >= OPS_THRESHOLDS.pushDeadLettersWarn) return 'warn';
      if (data.queueDepth >= OPS_THRESHOLDS.pushQueueDepthCritical) return 'critical';
      if (data.queueDepth >= OPS_THRESHOLDS.pushQueueDepthWarn) return 'warn';
      if (data.sendsFailure > 0 && data.sendsTotal > 0 && data.sendsFailure / data.sendsTotal > 0.1) {
        return 'warn';
      }
      return 'ok';
    }
    case 'deliveryReport': {
      const data = panel.data as OperationsSnapshot['deliveryReport'] extends PanelState<infer T> ? T : never;
      const openRate = data.inbox?.openRate ?? 0;
      if (openRate > 0 && openRate < OPS_THRESHOLDS.openRateWarn) return 'warn';
      const depth = data.queue?.depth ?? 0;
      if (depth >= OPS_THRESHOLDS.pushQueueDepthCritical) return 'critical';
      if (depth >= OPS_THRESHOLDS.pushQueueDepthWarn) return 'warn';
      return 'ok';
    }
    case 'mapHealth': {
      const data = panel.data as OperationsSnapshot['mapHealth'] extends PanelState<infer T> ? T : never;
      if (data.status === 'degraded') return 'warn';
      if (data.outboxPending >= OPS_THRESHOLDS.mapOutboxPendingCritical) return 'critical';
      if (data.outboxPending >= OPS_THRESHOLDS.mapOutboxPendingWarn) return 'warn';
      if (data.alerts.length > 0) return 'warn';
      return 'ok';
    }
    case 'mapDeep': {
      const data = panel.data as OperationsSnapshot['mapDeep'] extends PanelState<infer T> ? T : never;
      if (data.status === 'degraded') return 'warn';
      if (data.durationMs >= OPS_THRESHOLDS.mapDeepLatencyWarnMs) return 'warn';
      if (data.alerts.length > 0) return 'warn';
      return 'ok';
    }
    case 'deadLetters': {
      const data = panel.data as OperationsSnapshot['deadLetters'] extends PanelState<infer T> ? T : never;
      if (data.meta.total > 0) return 'warn';
      return 'ok';
    }
    case 'emailDeadLetters': {
      const data = panel.data as OperationsSnapshot['emailDeadLetters'] extends PanelState<infer T> ? T : never;
      if (data.meta.total >= OPS_THRESHOLDS.emailDeadLettersWarn) return 'warn';
      return 'ok';
    }
    case 'sideEffects': {
      const data = panel.data as OperationsSnapshot['sideEffects'] extends PanelState<infer T> ? T : never;
      if (data.pendingCount >= OPS_THRESHOLDS.sideEffectsPendingCritical) return 'critical';
      if (data.pendingCount >= OPS_THRESHOLDS.sideEffectsPendingWarn) return 'warn';
      return 'ok';
    }
    case 'workers': {
      const data = panel.data as OperationsSnapshot['workers'] extends PanelState<infer T> ? T : never;
      if (data.workers.some((worker) => worker.stale)) return 'warn';
      if (data.workers.some((worker) => worker.lastError)) return 'warn';
      return 'ok';
    }
    case 'readiness': {
      const data = panel.data as OperationsSnapshot['readiness'] extends PanelState<infer T> ? T : never;
      return data.status === 'ok' ? 'ok' : 'critical';
    }
    default:
      return 'ok';
  }
}

export function deriveSystemStatus(snapshot: OperationsSnapshot): SystemHealthSummary {
  const keys = Object.keys(snapshot) as OperationsPanelKey[];
  let okCount = 0;
  let warnCount = 0;
  let criticalCount = 0;
  let unknownCount = 0;

  for (const key of keys) {
    const health = derivePanelHealth(key, snapshot[key]);
    if (health === 'ok') okCount += 1;
    else if (health === 'warn') warnCount += 1;
    else if (health === 'critical') criticalCount += 1;
    else unknownCount += 1;
  }

  const status: HealthStatus =
    criticalCount > 0 ? 'critical' : warnCount > 0 ? 'warn' : unknownCount > 0 ? 'unknown' : 'ok';

  return { status, okCount, warnCount, criticalCount, unknownCount };
}

export function healthToBadgeTone(health: HealthStatus): 'success' | 'warning' | 'danger' | 'neutral' {
  if (health === 'ok') return 'success';
  if (health === 'warn') return 'warning';
  if (health === 'critical') return 'danger';
  return 'neutral';
}
