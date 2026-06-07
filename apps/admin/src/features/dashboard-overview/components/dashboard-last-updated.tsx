'use client';

import { useEffect, useState } from 'react';
import { useTranslations } from 'next-intl';
import { useDashboardSSE } from '../context/dashboard-sse-context';
import styles from './dashboard-last-updated.module.css';

export function DashboardLastUpdated() {
  const t = useTranslations('dashboard.timeAgo');
  const tCommon = useTranslations('common');
  const ctx = useDashboardSSE();
  const lastUpdatedAt = ctx?.lastUpdatedAt ?? Date.now();
  const [label, setLabel] = useState(() => tCommon('updated', { time: t('justNow') }));

  useEffect(() => {
    function formatTimeAgo(ms: number): string {
      if (ms < 60_000) return t('justNow');
      const minutes = Math.floor(ms / 60_000);
      if (minutes === 1) return t('minuteAgo');
      if (minutes < 60) return t('minutesAgo', { count: minutes });
      const hours = Math.floor(minutes / 60);
      if (hours === 1) return t('hourAgo');
      return t('hoursAgo', { count: hours });
    }

    const tick = () => {
      setLabel(tCommon('updated', { time: formatTimeAgo(Date.now() - lastUpdatedAt) }));
    };

    tick();
    const interval = window.setInterval(tick, 60_000);
    return () => window.clearInterval(interval);
  }, [lastUpdatedAt, t, tCommon]);

  return (
    <span className={styles.root} role="status" aria-live="polite">
      {label}
    </span>
  );
}
