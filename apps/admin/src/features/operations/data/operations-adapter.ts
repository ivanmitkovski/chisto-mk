import { serverAuthenticatedFetch } from '@/lib/auth/server-api-with-refresh';
import { getApiOrigin } from '@/lib/api';

type PanelState<T> =
  | { status: 'ok'; data: T; updatedAt: string }
  | { status: 'error'; error: string; updatedAt: string };

export type OperationsSnapshot = {
  pushStats: PanelState<{
    sendsTotal: number;
    sendsSuccess: number;
    sendsFailure: number;
    sendsRevoked: number;
    queueDepth: number;
    deadLetterCount: number;
  }>;
  deliveryReport: PanelState<{
    inbox?: { notificationsSent: number; notificationsOpened: number; openRate: number };
    queue?: { depth: number; activeLeases: number; deadLetterCount: number; retries: number };
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
  gdprAudit: PanelState<{ data: Array<{ id: string; action: string; createdAt: string; actorEmail: string | null }>; meta: { total: number } }>;
  feedDiagnostics: PanelState<{
    reasonCodes: Array<{ code: string; count: number }>;
    rankDriftSnapshot: Array<{ siteId: string; score: number; reasons: string[] }>;
    recentIntegrityDemotions: number;
  }>;
  sideEffects: PanelState<{ pendingCount: number }>;
  emailSuppressions: PanelState<{ meta: { total: number } }>;
};

const DEFAULT_PROBE_TIMEOUT_MS = 8_000;
const MAP_DEEP_TIMEOUT_MS = 15_000;

async function capture<T>(fn: () => Promise<T>): Promise<PanelState<T>> {
  const updatedAt = new Date().toISOString();
  try {
    return {
      status: 'ok',
      data: await fn(),
      updatedAt,
    };
  } catch (error) {
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
  const [pushStats, deliveryReport, deadLetters, mapHealth, mapDeep, gdprAudit, overview, sideEffects, emailSuppressions] =
    await Promise.all([
    capture(
      () =>
        fetchWithTimeout<OperationsSnapshot['pushStats'] extends PanelState<infer T> ? T : never>(
          '/notifications/admin/push-stats',
          DEFAULT_PROBE_TIMEOUT_MS,
          fetchOptions,
        ),
    ),
    capture(
      () =>
        fetchWithTimeout<OperationsSnapshot['deliveryReport'] extends PanelState<infer T> ? T : never>(
          '/notifications/admin/delivery-report',
          DEFAULT_PROBE_TIMEOUT_MS,
          fetchOptions,
        ),
    ),
    capture(
      () =>
        fetchWithTimeout<OperationsSnapshot['deadLetters'] extends PanelState<infer T> ? T : never>(
          '/notifications/admin/dead-letters?page=1&limit=5',
          DEFAULT_PROBE_TIMEOUT_MS,
          fetchOptions,
        )
    ),
    capture(
      () =>
        fetchWithTimeout<OperationsSnapshot['mapHealth'] extends PanelState<infer T> ? T : never>(
          '/health/map',
          DEFAULT_PROBE_TIMEOUT_MS,
          healthFetchOptions,
        )
    ),
    capture(
      () =>
        fetchWithTimeout<OperationsSnapshot['mapDeep'] extends PanelState<infer T> ? T : never>(
          '/health/map-deep',
          MAP_DEEP_TIMEOUT_MS,
          healthFetchOptions,
        )
    ),
    capture(
      () =>
        fetchWithTimeout<OperationsSnapshot['gdprAudit'] extends PanelState<infer T> ? T : never>(
          '/admin/audit?page=1&limit=10&resourceType=User',
          DEFAULT_PROBE_TIMEOUT_MS,
          fetchOptions,
        )
    ),
    capture(
      () =>
        fetchWithTimeout<{ feedDiagnostics: OperationsSnapshot['feedDiagnostics'] extends PanelState<infer T> ? T : never }>(
          '/admin/overview',
          DEFAULT_PROBE_TIMEOUT_MS,
          fetchOptions,
        ).then((o) => o.feedDiagnostics)
    ),
    capture(
      () =>
        fetchWithTimeout<{ pendingCount: number }>(
          '/admin/operations/report-side-effects/pending-count',
          DEFAULT_PROBE_TIMEOUT_MS,
          fetchOptions,
        )
    ),
    capture(
      () =>
        fetchWithTimeout<{ meta: { total: number } }>(
          '/admin/comms/email-suppressions?page=1&limit=1',
          DEFAULT_PROBE_TIMEOUT_MS,
          fetchOptions,
        ).then((r) => ({
          meta: r.meta,
        }))
    ),
  ]);

  return {
    pushStats,
    deliveryReport,
    deadLetters,
    mapHealth,
    mapDeep,
    gdprAudit,
    feedDiagnostics: overview,
    sideEffects,
    emailSuppressions,
  };
}
