'use client';

import { useEffect } from 'react';
import { getAdminCsrfHeaders } from '@/lib/auth/csrf-headers';

const KEEPALIVE_INTERVAL_MS = 10 * 60 * 1000;

/**
 * Proactively refreshes the admin session while the tab is visible,
 * keeping the short-lived access cookie warm before middleware or API calls need it.
 */
export function useAdminSessionKeepalive(): void {
  useEffect(() => {
    if (typeof document === 'undefined') return;

    let timer: ReturnType<typeof setInterval> | null = null;

    const refresh = () => {
      void fetch('/api/auth/refresh', {
        method: 'POST',
        headers: getAdminCsrfHeaders(),
        credentials: 'include',
      }).catch(() => undefined);
    };

    const start = () => {
      if (timer != null) return;
      refresh();
      timer = setInterval(refresh, KEEPALIVE_INTERVAL_MS);
    };

    const stop = () => {
      if (timer == null) return;
      clearInterval(timer);
      timer = null;
    };

    const onVisibilityChange = () => {
      if (document.hidden) {
        stop();
      } else {
        start();
      }
    };

    if (!document.hidden) {
      start();
    }

    document.addEventListener('visibilitychange', onVisibilityChange);
    return () => {
      document.removeEventListener('visibilitychange', onVisibilityChange);
      stop();
    };
  }, []);
}
