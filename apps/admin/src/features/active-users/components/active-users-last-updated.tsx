'use client';

import { useEffect, useState } from 'react';
import { useTranslations } from 'next-intl';
import { useActiveUsersLive } from '../hooks/use-active-users-live';
import styles from './active-users-header-chrome.module.css';

export function ActiveUsersLastUpdated() {
  const t = useTranslations('dashboard.timeAgo');
  const tCommon = useTranslations('common');
  const { lastUpdatedAt } = useActiveUsersLive();
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
      if (lastUpdatedAt <= 0) {
        setLabel(tCommon('updated', { time: t('justNow') }));
        return;
      }
      setLabel(tCommon('updated', { time: formatTimeAgo(Date.now() - lastUpdatedAt) }));
    };

    tick();
    const interval = window.setInterval(tick, 60_000);
    return () => window.clearInterval(interval);
  }, [lastUpdatedAt, t, tCommon]);

  return (
    <span className={styles.lastUpdated} role="status" aria-live="polite">
      {label}
    </span>
  );
}
