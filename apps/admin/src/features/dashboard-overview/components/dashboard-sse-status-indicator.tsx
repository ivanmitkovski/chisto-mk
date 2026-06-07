'use client';

import { useEffect, useRef, useState } from 'react';
import { useTranslations } from 'next-intl';
import { Button } from '@/components/ui';
import { useDashboardSSE } from '../context/dashboard-sse-context';
import styles from './dashboard-sse-status-indicator.module.css';

const HIDE_LIVE_AFTER_MS = 5000;

export function DashboardSSEStatusIndicator() {
  const t = useTranslations('dashboard.sse');
  const tCommon = useTranslations('common');
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

  if (ctx.disconnected) {
    return (
      <span className={styles.pillDisconnected} role="status" aria-label={t('disconnectedAria')}>
        <span className={styles.dotDisconnected} aria-hidden />
        {t('disconnected')}
        <Button variant="ghost" size="sm" onClick={() => ctx.requestReconnect()}>
          {t('reconnect')}
        </Button>
      </span>
    );
  }

  if (ctx.connected && showLive) {
    return (
      <span
        className={styles.pill}
        title={t('connected')}
        role="status"
        aria-label={t('liveConnectedAria')}
      >
        <span className={styles.dot} aria-hidden />
        {tCommon('live')}
      </span>
    );
  }

  if (!ctx.connected) {
    return (
      <span
        className={styles.pillReconnecting}
        title={t('reconnecting')}
        role="status"
        aria-label={t('reconnectingLabel')}
      >
        <span className={styles.dotReconnecting} aria-hidden />
        {t('reconnectingLabel')}
      </span>
    );
  }

  return null;
}
