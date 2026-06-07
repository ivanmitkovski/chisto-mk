'use client';

import { useQueryClient } from '@tanstack/react-query';
import { useRouter } from 'next/navigation';
import { useEffect } from 'react';
import { adminQueryKeys } from '@/lib/api';
import { useDashboardSSE } from '../context/dashboard-sse-context';

const POLL_INTERVAL_MS = 30_000;

/**
 * When SSE is disconnected, fall back to polling every 30s to keep data fresh.
 * Also refreshes RSC dashboard sections (overview stats/reports/insights).
 */
export function DashboardPollingFallback() {
  const queryClient = useQueryClient();
  const router = useRouter();
  const sseCtx = useDashboardSSE();

  useEffect(() => {
    if (!sseCtx?.connected && typeof document !== 'undefined' && !document.hidden) {
      const id = window.setInterval(() => {
        void queryClient.invalidateQueries({ queryKey: adminQueryKeys.root });
        sseCtx?.touchLastUpdated();
        router.refresh();
      }, POLL_INTERVAL_MS);
      return () => window.clearInterval(id);
    }
    return undefined;
  }, [queryClient, router, sseCtx?.connected]);

  return null;
}
