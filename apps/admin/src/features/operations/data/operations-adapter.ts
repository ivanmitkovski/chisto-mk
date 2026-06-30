import { serverAuthenticatedFetch } from '@/lib/auth/server-api-with-refresh';
import { ApiError } from '@/lib/api/api';
import { getApiOrigin } from '@/lib/api';
import {
  OPS_DEAD_LETTERS_PAGE_SIZE,
  OPS_MAP_DEEP_TIMEOUT_MS,
  OPS_PROBE_TIMEOUT_MS,
} from '../config';
import {
  normalizeDeliveryReport,
  normalizePushStats,
  sanitizeOperationsSnapshot,
  type OperationsSnapshot,
  type PanelState,
  type PushStatsData,
  type DeliveryReportData,
} from './operations-snapshot';

export type { OperationsSnapshot, PanelState, PushStatsData } from './operations-snapshot';
export { normalizePushStats, sanitizeOperationsSnapshot } from './operations-snapshot';

async function capture<T>(fn: () => Promise<T>): Promise<PanelState<T>> {
  const updatedAt = new Date().toISOString();
  try {
    return {
      status: 'ok',
      data: await fn(),
      updatedAt,
    };
  } catch (error) {
    if (error instanceof ApiError && error.status === 403) {
      return { status: 'forbidden', updatedAt };
    }
    const message =
      error instanceof Error && error.name === 'TimeoutError'
        ? 'Request timed out.'
        : error instanceof Error
          ? error.message
          : 'Unable to load panel.';
    return {
      status: 'error',
      error: message,
      updatedAt,
    };
  }
}

function fetchWithTimeout<T>(path: string, timeoutMs: number, fetchOptions: Record<string, unknown> = {}) {
  return serverAuthenticatedFetch<T>(path, { ...fetchOptions, timeoutMs });
}

export async function getOperationsSnapshot(): Promise<OperationsSnapshot> {
  const fetchOptions = {};
  const healthFetchOptions = { ...fetchOptions, baseUrl: getApiOrigin() };
  const deadLetterLimit = OPS_DEAD_LETTERS_PAGE_SIZE;

  const [
    pushStats,
    deliveryReport,
    pushDiagnostics,
    pushHealth,
    emailHealth,
    deadLetters,
    emailDeadLetters,
    mapHealth,
    mapDeep,
    gdprAudit,
    feedDiagnostics,
    sideEffects,
    emailSuppressions,
    systemInfo,
    workers,
    readiness,
  ] = await Promise.all([
    capture(() =>
      fetchWithTimeout<Partial<PushStatsData>>(
        '/notifications/admin/push-stats',
        OPS_PROBE_TIMEOUT_MS,
        fetchOptions,
      ).then(normalizePushStats),
    ),
    capture(() =>
      fetchWithTimeout<Partial<DeliveryReportData>>(
        '/notifications/admin/delivery-report',
        OPS_PROBE_TIMEOUT_MS,
        fetchOptions,
      ).then(normalizeDeliveryReport),
    ),
    capture(() =>
      fetchWithTimeout<OperationsSnapshot['pushDiagnostics'] extends PanelState<infer T> ? T : never>(
        '/notifications/admin/push-diagnostics',
        OPS_PROBE_TIMEOUT_MS,
        fetchOptions,
      ),
    ),
    capture(() =>
      fetchWithTimeout<OperationsSnapshot['pushHealth'] extends PanelState<infer T> ? T : never>(
        '/health/push',
        OPS_PROBE_TIMEOUT_MS,
        healthFetchOptions,
      ),
    ),
    capture(() =>
      fetchWithTimeout<OperationsSnapshot['emailHealth'] extends PanelState<infer T> ? T : never>(
        '/health/email',
        OPS_PROBE_TIMEOUT_MS,
        healthFetchOptions,
      ),
    ),
    capture(() =>
      fetchWithTimeout<OperationsSnapshot['deadLetters'] extends PanelState<infer T> ? T : never>(
        `/notifications/admin/dead-letters?page=1&limit=${deadLetterLimit}`,
        OPS_PROBE_TIMEOUT_MS,
        fetchOptions,
      ),
    ),
    capture(() =>
      fetchWithTimeout<OperationsSnapshot['emailDeadLetters'] extends PanelState<infer T> ? T : never>(
        `/admin/comms/email-dead-letters?page=1&limit=${deadLetterLimit}`,
        OPS_PROBE_TIMEOUT_MS,
        fetchOptions,
      ),
    ),
    capture(() =>
      fetchWithTimeout<OperationsSnapshot['mapHealth'] extends PanelState<infer T> ? T : never>(
        '/health/map',
        OPS_PROBE_TIMEOUT_MS,
        healthFetchOptions,
      ),
    ),
    capture(() =>
      fetchWithTimeout<OperationsSnapshot['mapDeep'] extends PanelState<infer T> ? T : never>(
        '/health/map-deep',
        OPS_MAP_DEEP_TIMEOUT_MS,
        healthFetchOptions,
      ),
    ),
    capture(() =>
      fetchWithTimeout<OperationsSnapshot['gdprAudit'] extends PanelState<infer T> ? T : never>(
        '/admin/audit?page=1&limit=10&resourceType=User',
        OPS_PROBE_TIMEOUT_MS,
        fetchOptions,
      ),
    ),
    capture(() =>
      fetchWithTimeout<OperationsSnapshot['feedDiagnostics'] extends PanelState<infer T> ? T : never>(
        '/admin/operations/feed-diagnostics',
        OPS_PROBE_TIMEOUT_MS,
        fetchOptions,
      ),
    ),
    capture(() =>
      fetchWithTimeout<{ pendingCount: number }>(
        '/admin/operations/report-side-effects/pending-count',
        OPS_PROBE_TIMEOUT_MS,
        fetchOptions,
      ),
    ),
    capture(() =>
      fetchWithTimeout<{ meta: { total: number } }>(
        '/admin/comms/email-suppressions?page=1&limit=1',
        OPS_PROBE_TIMEOUT_MS,
        fetchOptions,
      ).then((response) => ({ meta: response.meta })),
    ),
    capture(() =>
      fetchWithTimeout<OperationsSnapshot['systemInfo'] extends PanelState<infer T> ? T : never>(
        '/admin/operations/system-info',
        OPS_PROBE_TIMEOUT_MS,
        fetchOptions,
      ),
    ),
    capture(() =>
      fetchWithTimeout<OperationsSnapshot['workers'] extends PanelState<infer T> ? T : never>(
        '/admin/operations/workers',
        OPS_PROBE_TIMEOUT_MS,
        fetchOptions,
      ),
    ),
    capture(() =>
      fetchWithTimeout<OperationsSnapshot['readiness'] extends PanelState<infer T> ? T : never>(
        '/admin/operations/readiness',
        OPS_PROBE_TIMEOUT_MS,
        fetchOptions,
      ),
    ),
  ]);

  return sanitizeOperationsSnapshot({
    pushStats,
    deliveryReport,
    pushDiagnostics,
    pushHealth,
    emailHealth,
    deadLetters,
    emailDeadLetters,
    mapHealth,
    mapDeep,
    gdprAudit,
    feedDiagnostics,
    sideEffects,
    emailSuppressions,
    systemInfo,
    workers,
    readiness,
  });
}

export async function fetchOperationsMetricsSnapshot() {
  return fetchWithTimeout<{
    pushSendsSuccess: number;
    pushSendsFailure: number;
    pushQueueDepth: number;
    pushDeadLetterCount: number;
    mapOutboxPending: number;
    requestsFailed: number;
    emailQueueDepth: number;
    capturedAt: string;
  }>('/admin/operations/metrics-snapshot', OPS_PROBE_TIMEOUT_MS);
}
