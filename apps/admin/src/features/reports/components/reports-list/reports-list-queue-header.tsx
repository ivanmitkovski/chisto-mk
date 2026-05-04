'use client';

import Link from 'next/link';
import { Button, Icon } from '@/components/ui';
import styles from '../reports-list.module.css';

type ReportsListQueueHeaderProps = {
  reportsCount: number;
  needAttentionCount: number;
  duplicateCount: number;
  isRefreshing: boolean;
  onRefresh: () => void;
  sublineText: string;
};

export function ReportsListQueueHeader({
  reportsCount,
  needAttentionCount,
  duplicateCount,
  isRefreshing,
  onRefresh,
  sublineText,
}: ReportsListQueueHeaderProps) {
  return (
    <>
      <div className={styles.summaryStrip}>
        <span className={styles.summaryValue}>{reportsCount} reports</span>
        <span className={styles.summarySep}>·</span>
        <span className={styles.summaryValue}>{needAttentionCount} need attention</span>
        <span className={styles.summarySep}>·</span>
        <Link href="/dashboard/reports/duplicates" className={styles.summaryLink}>
          {duplicateCount} duplicate{duplicateCount !== 1 ? 's' : ''}
        </Link>
      </div>
      <span className={styles.sectionLabel}>Queue</span>
      <div className={styles.reportsHeader}>
        <div>
          <h2 id="reports-heading" className={styles.sectionTitle}>
            Reports
          </h2>
          <p className={styles.reportsSubline} data-attention={needAttentionCount > 0 ? 'true' : undefined}>
            {sublineText}
          </p>
        </div>
        <div className={styles.reportsHeaderActions}>
          <div className={styles.statusPill} role="status">
            <Button
              variant="icon"
              aria-label="Refresh reports"
              onClick={onRefresh}
              disabled={isRefreshing}
              className={styles.refreshBtn}
            >
              <Icon name="refresh" size={16} {...(isRefreshing && { className: styles.spinning })} />
            </Button>
          </div>
          <Link href="/dashboard/reports/duplicates" className={styles.viewAllLink}>
            {duplicateCount > 0
              ? `${duplicateCount} potential duplicate${duplicateCount !== 1 ? 's' : ''}`
              : 'Duplicates'}
            <Icon name="chevron-right" size={12} className={styles.linkChevron} aria-hidden />
          </Link>
        </div>
      </div>
    </>
  );
}
