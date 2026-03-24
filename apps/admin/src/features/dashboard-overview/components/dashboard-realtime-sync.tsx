'use client';

import { useEffect, useRef } from 'react';
import { useRouter } from 'next/navigation';

/**
 * Refreshes dashboard data when the user returns to the tab (visibility change).
 * Keeps data fresh without polling; manual refresh remains available.
 */
export function DashboardRealtimeSync() {
  const router = useRouter();
  const routerRef = useRef(router);
  routerRef.current = router;

  useEffect(() => {
    const onVisibilityChange = () => {
      if (!document.hidden) {
        routerRef.current.refresh();
      }
    };

    document.addEventListener('visibilitychange', onVisibilityChange);
    return () => document.removeEventListener('visibilitychange', onVisibilityChange);
  }, []);

  return null;
}
