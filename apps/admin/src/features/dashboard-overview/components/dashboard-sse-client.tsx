'use client';

import { useQueryClient } from '@tanstack/react-query';
import { fetchEventSource } from '@microsoft/fetch-event-source';
import { useRouter } from 'next/navigation';
import { useCallback, useEffect, useRef } from 'react';
import { useTranslations } from 'next-intl';
import { adminQueryKeys } from '@/lib/api';
import { emitNewReportSignal, emitCheckInRiskSignal, emitReportViewersUpdated } from '@/lib/realtime';
import { refreshAdminSession, signOutAndRedirectToLogin } from '@/features/auth/lib/admin-auth';
import { useDashboardSSE } from '../context/dashboard-sse-context';

const SSE_URL = '/api/admin/events';
const MAX_RETRIES = 10;
const MAX_RETRY_DELAY_MS = 30_000;
const PERIODIC_RECONNECT_MS = 60_000;
const DEBUG_REALTIME_FLAG = 'chisto:debug-realtime';
const MAX_AUTH_RECONNECTS = 2;
const REFRESH_DEBOUNCE_MS = 500;

function getRetryDelayMs(retryCount: number): number {
  const delay = Math.min(1000 * 2 ** retryCount, MAX_RETRY_DELAY_MS);
  return delay;
}

function isRealtimeDebugEnabled(): boolean {
  if (typeof window === 'undefined') return false;
  return process.env.NODE_ENV !== 'production' && window.localStorage.getItem(DEBUG_REALTIME_FLAG) === '1';
}

type ReportEventPayload = {
  type: 'report_created' | 'report_updated';
  reportId: string;
};

type ReportViewersUpdatedPayload = {
  type: 'report_viewers_updated';
  reportId: string;
  viewers: { sessionId: string; userId: string; displayName: string }[];
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

type CheckInRiskSignalSsePayload = {
  type: 'check_in_risk_signal_created' | 'check_in_risk_signal_updated';
  signalId: string;
  eventId?: string;
};

function isCheckInRiskSignalEvent(data: unknown): data is CheckInRiskSignalSsePayload {
  const d = data as Partial<CheckInRiskSignalSsePayload>;
  return (
    typeof data === 'object' &&
    data !== null &&
    typeof d.type === 'string' &&
    (d.type === 'check_in_risk_signal_created' || d.type === 'check_in_risk_signal_updated') &&
    typeof d.signalId === 'string'
  );
}

function isReportEvent(data: unknown): data is ReportEventPayload {
  const d = data as Partial<ReportEventPayload>;
  return (
    typeof data === 'object' &&
    data !== null &&
    typeof d.type === 'string' &&
    (d.type === 'report_created' || d.type === 'report_updated')
  );
}

function isReportViewersUpdatedEvent(data: unknown): data is ReportViewersUpdatedPayload {
  const d = data as Partial<ReportViewersUpdatedPayload>;
  return (
    typeof data === 'object' &&
    data !== null &&
    d.type === 'report_viewers_updated' &&
    typeof d.reportId === 'string' &&
    Array.isArray(d.viewers)
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

function invalidateAllAdminQueries(
  qc: ReturnType<typeof useQueryClient>,
): void {
  void qc.invalidateQueries({ queryKey: adminQueryKeys.root });
}

export function DashboardSSEClient() {
  const t = useTranslations('dashboard');
  const router = useRouter();
  const queryClient = useQueryClient();
  const sseCtx = useDashboardSSE();
  const routerRef = useRef(router);
  routerRef.current = router;
  const queryClientRef = useRef(queryClient);
  queryClientRef.current = queryClient;
  const abortRef = useRef<AbortController | null>(null);
  const mapInvalidateTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const retryCountRef = useRef(0);
  const authReconnectCountRef = useRef(0);
  const refreshTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const periodicReconnectTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  const sseCtxRef = useRef(sseCtx);
  sseCtxRef.current = sseCtx;

  const clearRefreshTimer = useCallback(() => {
    if (refreshTimerRef.current != null) {
      clearTimeout(refreshTimerRef.current);
      refreshTimerRef.current = null;
    }
  }, []);

  const clearPeriodicReconnect = useCallback(() => {
    if (periodicReconnectTimerRef.current != null) {
      clearTimeout(periodicReconnectTimerRef.current);
      periodicReconnectTimerRef.current = null;
    }
  }, []);

  const schedulePeriodicReconnect = useCallback((connect: () => void) => {
    clearPeriodicReconnect();
    periodicReconnectTimerRef.current = setTimeout(() => {
      periodicReconnectTimerRef.current = null;
      retryCountRef.current = 0;
      connect();
    }, PERIODIC_RECONNECT_MS);
  }, [clearPeriodicReconnect]);

  const scheduleRefresh = useCallback(() => {
    if (refreshTimerRef.current != null) return;
    refreshTimerRef.current = setTimeout(() => {
      refreshTimerRef.current = null;
      sseCtxRef.current?.touchLastUpdated();
      routerRef.current.refresh();
    }, REFRESH_DEBOUNCE_MS);
  }, []);

  const connect = useCallback(() => {
    void (async () => {
      if (abortRef.current) {
        abortRef.current.abort();
      }
      clearRefreshTimer();
      clearPeriodicReconnect();
      const controller = new AbortController();
      abortRef.current = controller;

      try {
        await fetchEventSource(SSE_URL, {
          signal: controller.signal,
          credentials: 'include',
          headers: {
            Accept: 'text/event-stream',
          },
          openWhenHidden: false,
          async onopen(response) {
            if (response.ok) {
              retryCountRef.current = 0;
              authReconnectCountRef.current = 0;
              sseCtxRef.current?.setConnected(true);
              sseCtxRef.current?.setDisconnected(false);
              if (isRealtimeDebugEnabled()) {
                console.debug('[realtime] sse-connected', { url: SSE_URL });
              }
              return;
            }
            if (response.status === 401) {
              const refreshed = await refreshAdminSession();
              if (refreshed === 'ok' && authReconnectCountRef.current < MAX_AUTH_RECONNECTS) {
                authReconnectCountRef.current += 1;
                throw new Error('SSE_AUTH_REFRESHED');
              }
              if (refreshed === 'unauthorized') {
                throw new Error('SSE_UNAUTHORIZED');
              }
              throw new Error('SSE_AUTH_TRANSIENT');
            }
            if (response.status === 403) {
              const refreshed = await refreshAdminSession();
              if (refreshed === 'ok' && authReconnectCountRef.current < MAX_AUTH_RECONNECTS) {
                authReconnectCountRef.current += 1;
                throw new Error('SSE_AUTH_REFRESHED');
              }
              throw new Error('SSE_AUTH_TRANSIENT');
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
                invalidateAllAdminQueries(qc);
                scheduleRefresh();
              } else if (isNotificationEvent(data)) {
                const message = data.title
                  ? `New notification: ${data.title}`
                  : 'New notification';
                sseCtxRef.current?.showRefreshToast(message);
                invalidateAllAdminQueries(qc);
                scheduleRefresh();
              } else if (isSiteEvent(data)) {
                sseCtxRef.current?.showRefreshToast(
                  data.type === 'site_created' ? 'New site created' : 'Site updated',
                );
                invalidateAllAdminQueries(qc);
                if (mapInvalidateTimerRef.current != null) {
                  clearTimeout(mapInvalidateTimerRef.current);
                }
                mapInvalidateTimerRef.current = setTimeout(() => {
                  void qc.invalidateQueries({
                    predicate: (query) => query.queryKey[0] === 'sites-map',
                  });
                }, 750);
                scheduleRefresh();
              } else if (isUserEvent(data)) {
                sseCtxRef.current?.showRefreshToast(
                  data.type === 'user_created' ? t('sse.newUserRegistered') : t('sse.userUpdated'),
                );
                invalidateAllAdminQueries(qc);
                scheduleRefresh();
              } else if (isCleanupEventSse(data)) {
                const label =
                  data.type === 'cleanup_event_pending'
                    ? t('sse.cleanupEventPending')
                    : data.type === 'cleanup_event_created'
                      ? t('sse.cleanupEventCreated')
                      : t('sse.cleanupEventUpdated');
                sseCtxRef.current?.showRefreshToast(label);
                invalidateAllAdminQueries(qc);
                scheduleRefresh();
              } else if (isCheckInRiskSignalEvent(data)) {
                emitCheckInRiskSignal(data.signalId);
                sseCtxRef.current?.showRefreshToast(t('sse.newCheckInRiskSignal'));
                scheduleRefresh();
              } else if (isReportViewersUpdatedEvent(data)) {
                emitReportViewersUpdated(data.reportId, data.viewers);
              } else if (
                typeof data === 'object' &&
                data !== null &&
                (data as { type?: string }).type &&
                ['active_users_updated', 'activity_event', 'alert_triggered'].includes(
                  (data as { type: string }).type,
                )
              ) {
                window.dispatchEvent(
                  new CustomEvent('chisto:active-users-sse', { detail: data }),
                );
                if ((data as { type: string }).type === 'alert_triggered') {
                  const alert = data as { message?: string };
                  sseCtxRef.current?.showRefreshToast(alert.message ?? 'Admin alert triggered');
                }
              }
            } catch {
              // Ignore parse errors (e.g. heartbeat)
            }
          },
          onerror(err) {
            if (err instanceof Error && err.message === 'SSE_AUTH_REFRESHED') {
              throw err;
            }
            if (
              err instanceof Error &&
              (err.message === 'SSE_UNAUTHORIZED' || err.message === 'SSE_AUTH_TRANSIENT')
            ) {
              throw err;
            }
            if (retryCountRef.current >= MAX_RETRIES) {
              return PERIODIC_RECONNECT_MS;
            }
            retryCountRef.current += 1;
            return getRetryDelayMs(retryCountRef.current);
          },
        });
      } catch (error) {
        sseCtxRef.current?.setConnected(false);
        if (error instanceof Error && error.message === 'SSE_AUTH_REFRESHED') {
          window.setTimeout(() => connect(), 0);
          return;
        }
        if (error instanceof Error && error.message === 'SSE_UNAUTHORIZED') {
          void signOutAndRedirectToLogin();
          return;
        }
        if (error instanceof Error && error.message === 'SSE_AUTH_TRANSIENT') {
          if (retryCountRef.current >= MAX_RETRIES) {
            sseCtxRef.current?.setDisconnected(true);
            schedulePeriodicReconnect(connect);
            return;
          }
          retryCountRef.current += 1;
          window.setTimeout(() => connect(), getRetryDelayMs(retryCountRef.current));
          return;
        }
        if (retryCountRef.current >= MAX_RETRIES) {
          sseCtxRef.current?.setDisconnected(true);
          schedulePeriodicReconnect(connect);
        }
      }
    })();
  }, [clearPeriodicReconnect, clearRefreshTimer, schedulePeriodicReconnect, scheduleRefresh]);

  useEffect(() => {
    if (typeof document === 'undefined') return;
    if (document.hidden) return;

    retryCountRef.current = 0;
    connect();

    const onVisibilityChange = () => {
      if (!document.hidden) {
        retryCountRef.current = 0;
        connect();
      } else if (abortRef.current) {
        abortRef.current.abort();
      }
    };

    const onOnline = () => {
      retryCountRef.current = 0;
      authReconnectCountRef.current = 0;
      clearPeriodicReconnect();
      connect();
    };

    document.addEventListener('visibilitychange', onVisibilityChange);
    window.addEventListener('online', onOnline);

    return () => {
      document.removeEventListener('visibilitychange', onVisibilityChange);
      window.removeEventListener('online', onOnline);
      if (abortRef.current) {
        abortRef.current.abort();
        abortRef.current = null;
      }
      if (mapInvalidateTimerRef.current != null) {
        clearTimeout(mapInvalidateTimerRef.current);
        mapInvalidateTimerRef.current = null;
      }
      clearRefreshTimer();
      clearPeriodicReconnect();
    };
  }, [clearPeriodicReconnect, clearRefreshTimer, connect, sseCtx?.reconnectNonce]);

  return null;
}
