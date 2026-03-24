'use client';

import { useEffect, useRef, useState } from 'react';
import { useDashboardSSE } from '../context/dashboard-sse-context';
import styles from './dashboard-sse-status-indicator.module.css';

const HIDE_LIVE_AFTER_MS = 5000;

export function DashboardSSEStatusIndicator() {
  const ctx = useDashboardSSE();
  const [showLive, setShowLive] = useState(false);
  const hideTimeoutRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  useEffect(() => {
    if (ctx?.connected) {
      setShowLive(true);
      if (hideTimeoutRef.current) {
        clearTimeout(hideTimeoutRef.current);
        hideTimeoutRef.current = null;
      }
      hideTimeoutRef.current = setTimeout(() => {
        setShowLive(false);
        hideTimeoutRef.current = null;
      }, HIDE_LIVE_AFTER_MS);
    } else {
      setShowLive(false);
      if (hideTimeoutRef.current) {
        clearTimeout(hideTimeoutRef.current);
        hideTimeoutRef.current = null;
      }
    }
    return () => {
      if (hideTimeoutRef.current) {
        clearTimeout(hideTimeoutRef.current);
      }
    };
  }, [ctx?.connected]);

  if (!ctx) return null;

  if (ctx.connected && showLive) {
    return (
      <span
        className={styles.pill}
        title="Real-time updates connected"
        role="status"
        aria-label="Live updates connected"
      >
        <span className={styles.dot} aria-hidden />
        Live
      </span>
    );
  }

  if (!ctx.connected) {
    return (
      <span
        className={styles.pillReconnecting}
        title="Reconnecting to real-time updates"
        role="status"
        aria-label="Reconnecting"
      >
        <span className={styles.dotReconnecting} aria-hidden />
        Reconnecting
      </span>
    );
  }

  return null;
}
