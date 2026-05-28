import { getAdminAuthTokenFromCookies } from '@/features/auth/lib/admin-auth-server';
import { apiFetch } from '@/lib/api';
import { getApiOrigin } from '@/lib/api-base-url';

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
  deadLetters: PanelState<{ data?: unknown[]; meta?: { total?: number } }>;
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
};

async function capture<T>(fn: () => Promise<T>): Promise<PanelState<T>> {
  const updatedAt = new Date().toISOString();
  try {
    return { status: 'ok', data: await fn(), updatedAt };
  } catch (error) {
    return {
      status: 'error',
      error: error instanceof Error ? error.message : 'Unable to load panel.',
      updatedAt,
    };
  }
}

export async function getOperationsSnapshot(): Promise<OperationsSnapshot> {
  const token = await getAdminAuthTokenFromCookies();
  const fetchOptions = { authToken: token };
  const healthFetchOptions = { ...fetchOptions, baseUrl: getApiOrigin() };
  const [pushStats, deliveryReport, deadLetters, mapHealth, mapDeep, gdprAudit] = await Promise.all([
    capture(() => apiFetch<OperationsSnapshot['pushStats'] extends PanelState<infer T> ? T : never>('/notifications/admin/push-stats', fetchOptions)),
    capture(() => apiFetch<OperationsSnapshot['deliveryReport'] extends PanelState<infer T> ? T : never>('/notifications/admin/delivery-report', fetchOptions)),
    capture(() => apiFetch<OperationsSnapshot['deadLetters'] extends PanelState<infer T> ? T : never>('/notifications/admin/dead-letters?page=1&limit=5', fetchOptions)),
    capture(() => apiFetch<OperationsSnapshot['mapHealth'] extends PanelState<infer T> ? T : never>('/health/map', healthFetchOptions)),
    capture(() => apiFetch<OperationsSnapshot['mapDeep'] extends PanelState<infer T> ? T : never>('/health/map-deep', healthFetchOptions)),
    capture(() => apiFetch<OperationsSnapshot['gdprAudit'] extends PanelState<infer T> ? T : never>('/admin/audit?page=1&limit=10&resourceType=User', fetchOptions)),
  ]);

  return { pushStats, deliveryReport, deadLetters, mapHealth, mapDeep, gdprAudit };
}
