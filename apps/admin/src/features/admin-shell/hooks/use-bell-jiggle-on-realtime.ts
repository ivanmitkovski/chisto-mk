'use client';

import { useCallback, useEffect, useState } from 'react';
import { subscribeNewReportSignal } from '@/lib/realtime';
import { useReducedMotion } from 'framer-motion';

const DEBUG_REALTIME_FLAG = 'chisto:debug-realtime';

export function useBellJiggleOnRealtime() {
  const reduceMotion = useReducedMotion();
  const [isBellJingling, setIsBellJingling] = useState(false);

  const isRealtimeDebugEnabled = useCallback(() => {
    if (typeof window === 'undefined') return false;
    return process.env.NODE_ENV !== 'production' && window.localStorage.getItem(DEBUG_REALTIME_FLAG) === '1';
  }, []);

  useEffect(() => {
    let bellJiggleTimeout: number | null = null;
    let lastBellJiggle = 0;

    const unsubscribe = subscribeNewReportSignal((payload) => {
      if (reduceMotion) return;
      const now = Date.now();
      if (now - lastBellJiggle < 3000) return;
      lastBellJiggle = now;
      setIsBellJingling(true);
      if (isRealtimeDebugEnabled()) {
        console.debug('[realtime] bell-jiggle', { reportId: payload.reportId, atMs: now });
      }
      if (bellJiggleTimeout != null) {
        window.clearTimeout(bellJiggleTimeout);
      }
      bellJiggleTimeout = window.setTimeout(() => {
        setIsBellJingling(false);
        bellJiggleTimeout = null;
      }, 650);
    });

    return () => {
      unsubscribe();
      if (bellJiggleTimeout != null) {
        window.clearTimeout(bellJiggleTimeout);
      }
    };
  }, [isRealtimeDebugEnabled, reduceMotion]);

  return { isBellJingling };
}
