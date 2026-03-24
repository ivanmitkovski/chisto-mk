'use client';

import { useQueryClient } from '@tanstack/react-query';
import { fetchEventSource } from '@microsoft/fetch-event-source';
import { useRouter } from 'next/navigation';
import { useCallback, useEffect, useRef } from 'react';
import { adminQueryKeys } from '@/lib/admin-api-client';
import { getAdminTokenFromBrowserCookie } from '@/features/auth/lib/admin-auth';
import { useDashboardSSE } from '../context/dashboard-sse-context';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL ?? 'http://localhost:3000';
const SSE_URL = `${API_BASE_URL}/admin/events`;
const MAX_RETRIES = 10;
const MAX_RETRY_DELAY_MS = 30_000;

function getRetryDelayMs(retryCount: number): number {
  const delay = Math.min(1000 * 2 ** retryCount, MAX_RETRY_DELAY_MS);
  return delay;
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

  const sseCtxRef = useRef(sseCtx);
  sseCtxRef.current = sseCtx;

  const connect = useCallback(() => {
    const token = getAdminTokenFromBrowserCookie();
    if (!token) return;

    if (abortRef.current) {
      abortRef.current.abort();
    }
    const controller = new AbortController();
    abortRef.current = controller;

    fetchEventSource(SSE_URL, {
      signal: controller.signal,
      headers: {
        Authorization: `Bearer ${token}`,
        Accept: 'text/event-stream',
      },
      openWhenHidden: false,
      async onopen(response) {
        if (response.ok) {
          retryCountRef.current = 0;
          sseCtxRef.current?.setConnected(true);
          return;
        }
        if (response.status === 401 || response.status === 403) {
          throw new Error('Unauthorized');
        }
        throw new Error(`SSE connection failed: ${response.status}`);
      },
      onmessage(ev) {
        try {
          const data = JSON.parse(ev.data) as unknown;
          const qc = queryClientRef.current;
          if (isReportEvent(data)) {
            if (data.type === 'report_created') {
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
          }
        } catch {
          // Ignore parse errors (e.g. heartbeat)
        }
      },
      onerror(err) {
        if (err instanceof Error && err.message === 'Unauthorized') {
          throw err;
        }
        if (retryCountRef.current >= MAX_RETRIES) {
          throw err;
        }
        retryCountRef.current += 1;
        return getRetryDelayMs(retryCountRef.current);
      },
    }).catch(() => {
      sseCtxRef.current?.setConnected(false);
      // Connection closed or fatal error - will reconnect on visibility change
    });
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
