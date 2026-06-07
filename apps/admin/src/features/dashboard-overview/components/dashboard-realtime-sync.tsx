'use client';

import { useEffect, useRef } from 'react';
import { useRouter } from 'next/navigation';
import { useDashboardSSE } from '../context/dashboard-sse-context';

/**
 * Refreshes dashboard data when the user returns to the tab (visibility change).
 * Keeps data fresh without polling; manual refresh remains available.
 */
export function DashboardRealtimeSync() {
  const router = useRouter();
  const sseCtx = useDashboardSSE();
  const routerRef = useRef(router);
  routerRef.current = router;

  useEffect(() => {
    const onVisibilityChange = () => {
      if (!document.hidden) {
        sseCtx?.touchLastUpdated();
        routerRef.current.refresh();
      }
    };

    document.addEventListener('visibilitychange', onVisibilityChange);
    return () => document.removeEventListener('visibilitychange', onVisibilityChange);
  }, []);

  return null;
}
