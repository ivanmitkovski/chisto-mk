'use client';

import { Card } from '@/components/ui';
import styles from '../reports-list.module.css';

type ReportsListSkeletonProps = {
  embedded?: boolean;
};

export function ReportsListSkeleton({ embedded = false }: ReportsListSkeletonProps) {
  if (embedded) {
    return (
      <div className={styles.section} aria-busy="true">
        <div className={styles.toolbar}>
          <div className={styles.filterRow}>
            <div className={styles.filterChips}>
              {[1, 2, 3, 4, 5].map((i) => (
                <span key={i} className={styles.filterChipSkeleton} />
              ))}
            </div>
          </div>
        </div>
        <Card as="div" padding="sm" className={styles.tableCard}>
          <div className={styles.tableSkeleton}>
            {Array.from({ length: 5 }).map((_, i) => (
              <div key={i} className={styles.rowSkeleton} />
            ))}
          </div>
        </Card>
      </div>
    );
  }
  return (
    <section className={styles.section} aria-busy="true">
      <div className={styles.summaryStrip}>
        <span className={styles.summaryValue}>—</span>
        <span className={styles.summarySep}>·</span>
        <span className={styles.summaryValue}>—</span>
        <span className={styles.summarySep}>·</span>
        <span className={styles.summaryValue}>—</span>
      </div>
      <span className={styles.sectionLabel}>Queue</span>
      <div className={styles.reportsHeader}>
        <div>
          <div className={styles.titleSkeleton} />
          <div className={styles.subtitleSkeleton} />
        </div>
      </div>
      <div className={styles.toolbar}>
        <div className={styles.filterRow}>
          <div className={styles.filterChips}>
            {[1, 2, 3, 4, 5].map((i) => (
              <span key={i} className={styles.filterChipSkeleton} />
            ))}
          </div>
        </div>
      </div>
      <Card as="div" padding="sm" className={styles.tableCard}>
        <div className={styles.tableSkeleton}>
          {Array.from({ length: 6 }).map((_, i) => (
            <div key={i} className={styles.rowSkeleton} />
          ))}
        </div>
      </Card>
    </section>
  );
}
