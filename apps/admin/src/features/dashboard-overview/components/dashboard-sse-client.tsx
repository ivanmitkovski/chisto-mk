'use client';

import { useQueryClient } from '@tanstack/react-query';
import { fetchEventSource } from '@microsoft/fetch-event-source';
import { useRouter } from 'next/navigation';
import { useCallback, useEffect, useRef } from 'react';
import { adminQueryKeys } from '@/lib/admin-api-client';
import { getApiBaseUrl } from '@/lib/api-base-url';
import { emitNewReportSignal } from '@/lib/realtime-signals';
import {
  getAdminTokenFromBrowserCookie,
  refreshAdminAccessTokenInBrowser,
  shouldProactivelyRefreshAdminAccessToken,
} from '@/features/auth/lib/admin-auth';
import { useDashboardSSE } from '../context/dashboard-sse-context';

const SSE_URL = `${getApiBaseUrl()}/admin/events`;
const MAX_RETRIES = 10;
const MAX_RETRY_DELAY_MS = 30_000;
const DEBUG_REALTIME_FLAG = 'chisto:debug-realtime';

function getRetryDelayMs(retryCount: number): number {
  const delay = Math.min(1000 * 2 ** retryCount, MAX_RETRY_DELAY_MS);
  return delay;
}

function isRealtimeDebugEnabled(): boolean {
  if (typeof window === 'undefined') return false;
  return process.env.NODE_ENV !== 'production' && window.localStorage.getItem(DEBUG_REALTIME_FLAG) === '1';
}

/** Thrown from SSE `onopen` after a successful refresh so the client reconnects with a new JWT. */
class SSEAuthRefreshedError extends Error {
  constructor() {
    super('SSE authentication renewed');
    this.name = 'SSEAuthRefreshedError';
  }
}

type ReportEventPayload = {
  type: 'report_created' | 'report_updated';
  reportId: string;
};

type NotificationEventPayload = {
  type: 'notification_created';
  notificationId: string;
  title?: string;
};

type SiteEventPayload = {
  type: 'site_created' | 'site_updated';
  siteId: string;
};

type UserEventPayload = {
  type: 'user_created' | 'user_updated';
  userId: string;
};

type CleanupEventSsePayload = {
  type: 'cleanup_event_created' | 'cleanup_event_updated' | 'cleanup_event_pending';
  eventId: string;
  moderationStatus?: string;
  lifecycleStatus?: string;
};

function isReportEvent(data: unknown): data is ReportEventPayload {
  const d = data as Partial<ReportEventPayload>;
  return (
    typeof data === 'object' &&
    data !== null &&
    typeof d.type === 'string' &&
    (d.type === 'report_created' || d.type === 'report_updated')
  );
}

function isNotificationEvent(data: unknown): data is NotificationEventPayload {
  const d = data as Partial<NotificationEventPayload>;
  return (
    typeof data === 'object' &&
    data !== null &&
    typeof d.type === 'string' &&
    d.type === 'notification_created'
  );
}

function isSiteEvent(data: unknown): data is SiteEventPayload {
  const d = data as Partial<SiteEventPayload>;
  return (
    typeof data === 'object' &&
    data !== null &&
    typeof d.type === 'string' &&
    (d.type === 'site_created' || d.type === 'site_updated')
  );
}

function isUserEvent(data: unknown): data is UserEventPayload {
  const d = data as Partial<UserEventPayload>;
  return (
    typeof data === 'object' &&
    data !== null &&
    typeof d.type === 'string' &&
    (d.type === 'user_created' || d.type === 'user_updated')
  );
}

function isCleanupEventSse(data: unknown): data is CleanupEventSsePayload {
  const d = data as Partial<CleanupEventSsePayload>;
  return (
    typeof data === 'object' &&
    data !== null &&
    typeof d.type === 'string' &&
    (d.type === 'cleanup_event_created' ||
      d.type === 'cleanup_event_updated' ||
      d.type === 'cleanup_event_pending') &&
    typeof d.eventId === 'string'
  );
}

export function DashboardSSEClient() {
  const router = useRouter();
  const queryClient = useQueryClient();
  const sseCtx = useDashboardSSE();
  const routerRef = useRef(router);
  routerRef.current = router;
  const queryClientRef = useRef(queryClient);
  queryClientRef.current = queryClient;
  const abortRef = useRef<AbortController | null>(null);
  const retryCountRef = useRef(0);
  const ssePostRefreshReconnectsRef = useRef(0);

  const sseCtxRef = useRef(sseCtx);
  sseCtxRef.current = sseCtx;

  const connect = useCallback(() => {
    void (async () => {
      let token = getAdminTokenFromBrowserCookie();
      if (!token) return;

      if (shouldProactivelyRefreshAdminAccessToken(token)) {
        await refreshAdminAccessTokenInBrowser();
        token = getAdminTokenFromBrowserCookie();
        if (!token) return;
      }

      if (abortRef.current) {
        abortRef.current.abort();
      }
      const controller = new AbortController();
      abortRef.current = controller;

      try {
        await fetchEventSource(SSE_URL, {
          signal: controller.signal,
          headers: {
            Authorization: `Bearer ${token}`,
            Accept: 'text/event-stream',
          },
          openWhenHidden: false,
          async onopen(response) {
            if (response.ok) {
              retryCountRef.current = 0;
              ssePostRefreshReconnectsRef.current = 0;
              sseCtxRef.current?.setConnected(true);
              if (isRealtimeDebugEnabled()) {
                console.debug('[realtime] sse-connected', { url: SSE_URL });
              }
              return;
            }
            if (response.status === 401) {
              const refreshed = await refreshAdminAccessTokenInBrowser();
              if (refreshed) {
                sseCtxRef.current?.setConnected(false);
                throw new SSEAuthRefreshedError();
              }
              throw new Error('Unauthorized');
            }
            if (response.status === 403) {
              throw new Error('Unauthorized');
            }
            throw new Error(`SSE connection failed: ${response.status}`);
          },
          onmessage(ev) {
            try {
              const data = JSON.parse(ev.data) as unknown;
              if (isRealtimeDebugEnabled()) {
                console.debug('[realtime] sse-event', data);
              }
              const qc = queryClientRef.current;
              if (isReportEvent(data)) {
                if (data.type === 'report_created') {
                  emitNewReportSignal(data.reportId);
                  sseCtxRef.current?.showRefreshToast('New report received');
                }
                void qc.invalidateQueries({ queryKey: adminQueryKeys.reportsAll });
                void qc.invalidateQueries({ queryKey: adminQueryKeys.overview });
                routerRef.current.refresh();
              } else if (isNotificationEvent(data)) {
                const message = data.title
                  ? `New notification: ${data.title}`
                  : 'New notification';
                sseCtxRef.current?.showRefreshToast(message);
                void qc.invalidateQueries({ queryKey: adminQueryKeys.notifications });
                void qc.invalidateQueries({ queryKey: adminQueryKeys.overview });
                routerRef.current.refresh();
              } else if (isSiteEvent(data)) {
                sseCtxRef.current?.showRefreshToast(
                  data.type === 'site_created' ? 'New site created' : 'Site updated',
                );
                void qc.invalidateQueries({ queryKey: adminQueryKeys.sitesAll });
                void qc.invalidateQueries({ queryKey: adminQueryKeys.sitesStats });
                void qc.invalidateQueries({ queryKey: adminQueryKeys.overview });
                routerRef.current.refresh();
              } else if (isUserEvent(data)) {
                sseCtxRef.current?.showRefreshToast(
                  data.type === 'user_created' ? 'New user registered' : 'User updated',
                );
                void qc.invalidateQueries({ queryKey: adminQueryKeys.usersAll });
                void qc.invalidateQueries({ queryKey: adminQueryKeys.usersStats });
                void qc.invalidateQueries({ queryKey: adminQueryKeys.overview });
                routerRef.current.refresh();
              } else if (isCleanupEventSse(data)) {
                const label =
                  data.type === 'cleanup_event_pending'
                    ? 'Cleanup event pending review'
                    : data.type === 'cleanup_event_created'
                      ? 'New cleanup event'
                      : 'Cleanup event updated';
                sseCtxRef.current?.showRefreshToast(label);
                routerRef.current.refresh();
              }
            } catch {
              // Ignore parse errors (e.g. heartbeat)
            }
          },
          onerror(err) {
            if (err instanceof SSEAuthRefreshedError) {
              throw err;
            }
            if (err instanceof Error && err.message === 'Unauthorized') {
              throw err;
            }
            if (retryCountRef.current >= MAX_RETRIES) {
              throw err;
            }
            retryCountRef.current += 1;
            return getRetryDelayMs(retryCountRef.current);
          },
        });
      } catch (err) {
        sseCtxRef.current?.setConnected(false);
        if (err instanceof SSEAuthRefreshedError && ssePostRefreshReconnectsRef.current < 3) {
          ssePostRefreshReconnectsRef.current += 1;
          setTimeout(() => connect(), 0);
        }
      }
    })();
  }, []);

  useEffect(() => {
    if (typeof document === 'undefined') return;
    if (document.hidden) return;

    connect();

    const onVisibilityChange = () => {
      if (!document.hidden) {
        retryCountRef.current = 0;
        connect();
      } else if (abortRef.current) {
        abortRef.current.abort();
      }
    };

    document.addEventListener('visibilitychange', onVisibilityChange);

    return () => {
      document.removeEventListener('visibilitychange', onVisibilityChange);
      if (abortRef.current) {
        abortRef.current.abort();
        abortRef.current = null;
      }
    };
  }, [connect]);

  return null;
}
