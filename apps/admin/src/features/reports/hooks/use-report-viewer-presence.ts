'use client';

import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import {
  subscribeReportViewersUpdated,
  type ReportViewerPresenceEntry,
} from '@/lib/realtime';

const HEARTBEAT_INTERVAL_MS = 20_000;
const POLL_FALLBACK_MS = 60_000;

type ViewersResponse = {
  viewers: ReportViewerPresenceEntry[];
};

type UseReportViewerPresenceOptions = {
  reportId: string;
  moderatorId?: string;
  moderatorDisplayName?: string;
  enabled?: boolean;
};

function createSessionId(): string {
  return crypto.randomUUID();
}

async function fetchViewers(reportId: string): Promise<ReportViewerPresenceEntry[]> {
  const response = await fetch(`/api/reports/${reportId}/viewers`, { cache: 'no-store' });
  if (!response.ok) {
    return [];
  }
  const data = (await response.json()) as ViewersResponse;
  return Array.isArray(data.viewers) ? data.viewers : [];
}

async function postHeartbeat(
  reportId: string,
  sessionId: string,
  displayName: string,
): Promise<ReportViewerPresenceEntry[]> {
  const response = await fetch(`/api/reports/${reportId}/viewers`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ sessionId, displayName }),
    cache: 'no-store',
  });
  if (!response.ok) {
    return [];
  }
  const data = (await response.json()) as ViewersResponse;
  return Array.isArray(data.viewers) ? data.viewers : [];
}

function leavePresence(reportId: string, sessionId: string): void {
  const url = `/api/reports/${reportId}/viewers/${encodeURIComponent(sessionId)}`;
  void fetch(url, { method: 'DELETE', keepalive: true });
}

export function useReportViewerPresence({
  reportId,
  moderatorId,
  moderatorDisplayName,
  enabled = true,
}: UseReportViewerPresenceOptions) {
  const sessionIdRef = useRef<string>(createSessionId());
  const [allViewers, setAllViewers] = useState<ReportViewerPresenceEntry[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const lastRealtimeAtRef = useRef(0);
  const heartbeatTimerRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const pollTimerRef = useRef<ReturnType<typeof setInterval> | null>(null);

  const displayName = moderatorDisplayName?.trim() || 'Moderator';

  const applyViewers = useCallback((viewers: ReportViewerPresenceEntry[]) => {
    setAllViewers(viewers);
    setIsLoading(false);
  }, []);

  const sendHeartbeat = useCallback(async () => {
    if (!enabled || document.hidden) return;
    const viewers = await postHeartbeat(reportId, sessionIdRef.current, displayName);
    applyViewers(viewers);
  }, [applyViewers, displayName, enabled, reportId]);

  useEffect(() => {
    if (!enabled) {
      setIsLoading(false);
      return;
    }

    let cancelled = false;

    void (async () => {
      const viewers = await fetchViewers(reportId);
      if (!cancelled) {
        applyViewers(viewers);
      }
      if (!cancelled) {
        await sendHeartbeat();
      }
    })();

    heartbeatTimerRef.current = setInterval(() => {
      void sendHeartbeat();
    }, HEARTBEAT_INTERVAL_MS);

    pollTimerRef.current = setInterval(() => {
      if (Date.now() - lastRealtimeAtRef.current < POLL_FALLBACK_MS) {
        return;
      }
      void fetchViewers(reportId).then((viewers) => {
        if (!cancelled) {
          applyViewers(viewers);
        }
      });
    }, POLL_FALLBACK_MS);

    const onVisibilityChange = () => {
      if (!document.hidden) {
        void sendHeartbeat();
      }
    };

    document.addEventListener('visibilitychange', onVisibilityChange);

    return () => {
      cancelled = true;
      document.removeEventListener('visibilitychange', onVisibilityChange);
      if (heartbeatTimerRef.current != null) {
        clearInterval(heartbeatTimerRef.current);
        heartbeatTimerRef.current = null;
      }
      if (pollTimerRef.current != null) {
        clearInterval(pollTimerRef.current);
        pollTimerRef.current = null;
      }
      leavePresence(reportId, sessionIdRef.current);
    };
  }, [applyViewers, enabled, reportId, sendHeartbeat]);

  useEffect(() => {
    if (!enabled) return;

    return subscribeReportViewersUpdated((payload) => {
      if (payload.reportId !== reportId) return;
      lastRealtimeAtRef.current = payload.atMs;
      applyViewers(payload.viewers);
    });
  }, [applyViewers, enabled, reportId]);

  const otherViewers = useMemo(() => {
    if (!moderatorId) {
      return allViewers;
    }
    return allViewers.filter((viewer) => viewer.userId !== moderatorId);
  }, [allViewers, moderatorId]);

  return { allViewers, otherViewers, isLoading };
}
