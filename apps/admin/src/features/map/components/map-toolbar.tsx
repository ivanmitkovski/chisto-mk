'use client';

import { useRouter, useSearchParams } from 'next/navigation';
import { useCallback } from 'react';
import { Icon } from '@/components/ui';
import styles from './sites-map.module.css';

const STATUS_OPTIONS = [
  { value: '', label: 'All' },
  { value: 'REPORTED', label: 'Reported' },
  { value: 'VERIFIED', label: 'Verified' },
  { value: 'CLEANUP_SCHEDULED', label: 'Cleanup scheduled' },
  { value: 'IN_PROGRESS', label: 'In progress' },
  { value: 'CLEANED', label: 'Cleaned' },
  { value: 'DISPUTED', label: 'Disputed' },
] as const;

type MapToolbarProps = {
  statusFilter: string;
  onStatusChange: (status: string) => void;
  onFitBounds: () => void;
  onRefresh: () => void;
};

export function MapToolbar({ statusFilter, onStatusChange, onFitBounds, onRefresh }: MapToolbarProps) {
  const router = useRouter();
  const searchParams = useSearchParams();

  const handleStatusClick = useCallback(
    (value: string) => {
      onStatusChange(value);
      const next = new URLSearchParams(searchParams.toString());
      if (value) {
        next.set('status', value);
      } else {
        next.delete('status');
      }
      const qs = next.toString();
      router.replace(qs ? `/dashboard/map?${qs}` : '/dashboard/map', { scroll: false });
    },
    [onStatusChange, router, searchParams],
  );

  return (
    <div
      className={styles.toolbar}
      role="toolbar"
      aria-label="Map filters and actions"
      onWheelCapture={(e) => e.stopPropagation()}
      onDoubleClickCapture={(e) => e.stopPropagation()}
    >
      <div className={styles.toolbarLeading}>
        <div className={styles.statusChips}>
          {STATUS_OPTIONS.map(({ value, label }) => (
            <button
              key={value || 'all'}
              type="button"
              className={`${styles.chip} ${statusFilter === value ? styles.chipActive : ''}`}
              onClick={() => handleStatusClick(value)}
              aria-pressed={statusFilter === value}
            >
              {label}
            </button>
          ))}
        </div>
      </div>
      <div className={styles.toolbarDivider} aria-hidden />
      <div className={styles.toolbarActions}>
        <button
          type="button"
          className={styles.toolbarBtn}
          onClick={onFitBounds}
          aria-label="Fit map to North Macedonia bounds"
        >
          <Icon name="location" size={16} />
          Fit bounds
        </button>
        <button
          type="button"
          className={styles.toolbarBtn}
          onClick={onRefresh}
          aria-label="Refresh map data"
        >
          <Icon name="refresh" size={16} />
          Refresh
        </button>
      </div>
    </div>
  );
}
