'use client';

import { useEffect, useState } from 'react';
import styles from './dashboard-last-updated.module.css';

function formatTimeAgo(ms: number): string {
  if (ms < 60_000) return 'just now';
  const minutes = Math.floor(ms / 60_000);
  if (minutes === 1) return '1 minute ago';
  if (minutes < 60) return `${minutes} minutes ago`;
  const hours = Math.floor(minutes / 60);
  if (hours === 1) return '1 hour ago';
  return `${hours} hours ago`;
}

export function DashboardLastUpdated() {
  const [mountedAt] = useState(() => Date.now());
  const [label, setLabel] = useState('Updated just now');

  useEffect(() => {
    const tick = () => {
      setLabel(`Updated ${formatTimeAgo(Date.now() - mountedAt)}`);
    };

    tick();

    const interval = window.setInterval(tick, 60_000);
    return () => window.clearInterval(interval);
  }, [mountedAt]);

  return (
    <span className={styles.root} role="status" aria-live="polite">
      {label}
    </span>
  );
}
