import { serverAuthenticatedFetch } from '@/lib/auth/server-api-with-refresh';
import { ApiError } from '@/lib/api/api';
import { getApiOrigin } from '@/lib/api';
import {
  OPS_DEAD_LETTERS_PAGE_SIZE,
  OPS_MAP_DEEP_TIMEOUT_MS,
  OPS_PROBE_TIMEOUT_MS,
} from '../config';

export type PanelState<T> =
  | { status: 'ok'; data: T; updatedAt: string }
  | { status: 'error'; error: string; updatedAt: string }
  | { status: 'forbidden'; updatedAt: string };

export type OperationsSnapshot = {
  pushStats: PanelState<{
    sendsTotal: number;
    sendsSuccess: number;
    sendsFailure: number;
    sendsRevoked: number;
    sendsByType: Record<string, { success: number; failure: number; revoked: number }>;
    tokenRevocations: number;
    queueRetries: number;
    inboxReads: number;
    queueDepth: number;
    activeLeases: number;
    deadLetterCount: number;
  }>;
  deliveryReport: PanelState<{
    sends: {
      total: number;
      success: number;
      failure: number;
      revoked: number;
      byType: Record<string, { success: number; failure: number; revoked: number }>;
    };
    inbox: { notificationsSent: number; notificationsOpened: number; openRate: number };
    queue: { depth: number; activeLeases: number; deadLetterCount: number; retries: number };
  }>;
  deadLetters: PanelState<{
    data: Array<{
      id: string;
      userNotificationId: string;
      deviceTokenSuffix: string;
      attempts: number;
      lastErrorCode: string | null;
      lastErrorMessage: string | null;
      lastAttemptAt: string | null;
      createdAt: string;
    }>;
    meta: { page: number; limit: number; total: number };
  }>;
  emailDeadLetters: PanelState<{
    data: Array<{
      id: string;
      userId: string;
      templateId: string;
      attempts: number;
      lastError: string | null;
      lastAttemptAt: string | null;
      createdAt: string;
    }>;
    meta: { page: number; limit: number; total: number };
  }>;
  mapHealth: PanelState<{
    status: string;
    mapUseProjection: boolean;
    outboxPending: number;
    staleHotProjectionRows: number;
    alerts: string[];
  }>;
  mapDeep: PanelState<{
    status: string;
    durationMs: number;
    matchCount: number;
    queryPath: string;
    alerts: string[];
  }>;
  gdprAudit: PanelState<{
    data: Array<{ id: string; action: string; createdAt: string; actorEmail: string | null }>;
    meta: { total: number };
  }>;
  feedDiagnostics: PanelState<{
    reasonCodes: Array<{ code: string; count: number }>;
    rankDriftSnapshot: Array<{ siteId: string; score: number; reasons: string[] }>;
    recentIntegrityDemotions: number;
  }>;
  sideEffects: PanelState<{ pendingCount: number }>;
  emailSuppressions: PanelState<{ meta: { total: number } }>;
  systemInfo: PanelState<{
    version: string;
    gitSha: string | null;
    nodeEnv: string;
    region: string | null;
    startedAt: string;
    uptimeSeconds: number;
    fcmEnabled: boolean;
  }>;
  workers: PanelState<{
    workers: Array<{
      name: string;
      running: boolean;
      intervalMs: number;
      startedAt: string;
      lastRunAt: string | null;
      lastSuccessAt: string | null;
      lastError: string | null;
      stale: boolean;
    }>;
    perReplica: boolean;
  }>;
  readiness: PanelState<{
    status: 'ok' | 'degraded';
    database: 'ok' | 'fail';
    redis: string;
    s3: string;
  }>;
};

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
    deadLetters,
    emailDeadLetters,
    mapHealth,
    mapDeep,
    gdprAudit,
    overview,
    sideEffects,
    emailSuppressions,
    systemInfo,
    workers,
    readiness,
  ] = await Promise.all([
    capture(() =>
      fetchWithTimeout<OperationsSnapshot['pushStats'] extends PanelState<infer T> ? T : never>(
        '/notifications/admin/push-stats',
        OPS_PROBE_TIMEOUT_MS,
        fetchOptions,
      ),
    ),
    capture(() =>
      fetchWithTimeout<OperationsSnapshot['deliveryReport'] extends PanelState<infer T> ? T : never>(
        '/notifications/admin/delivery-report',
        OPS_PROBE_TIMEOUT_MS,
        fetchOptions,
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
      fetchWithTimeout<{ feedDiagnostics: OperationsSnapshot['feedDiagnostics'] extends PanelState<infer T> ? T : never }>(
        '/admin/overview',
        OPS_PROBE_TIMEOUT_MS,
        fetchOptions,
      ).then((response) => response.feedDiagnostics),
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

  return {
    pushStats,
    deliveryReport,
    deadLetters,
    emailDeadLetters,
    mapHealth,
    mapDeep,
    gdprAudit,
    feedDiagnostics: overview,
    sideEffects,
    emailSuppressions,
    systemInfo,
    workers,
    readiness,
  };
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
