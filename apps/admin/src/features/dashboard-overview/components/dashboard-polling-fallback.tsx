'use client';

import { useQueryClient } from '@tanstack/react-query';
import { useEffect } from 'react';
import { adminQueryKeys } from '@/lib/admin-api-client';
import { useDashboardSSE } from '../context/dashboard-sse-context';

const POLL_INTERVAL_MS = 30_000;

/**
 * When SSE is disconnected, fall back to polling every 30s to keep data fresh.
 * Does not show errors; data still works, just not real-time.
 */
export function DashboardPollingFallback() {
  const queryClient = useQueryClient();
  const sseCtx = useDashboardSSE();

  useEffect(() => {
    if (!sseCtx?.connected && typeof document !== 'undefined' && !document.hidden) {
      const id = window.setInterval(() => {
        void queryClient.invalidateQueries({ queryKey: adminQueryKeys.overview });
        void queryClient.invalidateQueries({ queryKey: adminQueryKeys.reportsAll });
        void queryClient.invalidateQueries({ queryKey: adminQueryKeys.notifications });
        void queryClient.invalidateQueries({ queryKey: adminQueryKeys.usersAll });
        void queryClient.invalidateQueries({ queryKey: adminQueryKeys.sitesAll });
      }, POLL_INTERVAL_MS);
      return () => window.clearInterval(id);
    }
    return undefined;
  }, [queryClient, sseCtx?.connected]);

  return null;
}
