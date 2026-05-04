'use client';

import { Icon } from '@/components/ui';
import styles from '../reports-list.module.css';

type ReportsListEmptyStateProps = {
  totalReportsCount: number;
  filteredByStatusCount: number;
  debouncedSearch: string;
};

export function ReportsListEmptyState({
  totalReportsCount,
  filteredByStatusCount,
  debouncedSearch,
}: ReportsListEmptyStateProps) {
  return (
    <div className={styles.emptyState}>
      {totalReportsCount === 0 ? (
        <>
          <Icon name="document-text" size={40} className={styles.emptyStateIcon} aria-hidden />
          <p>No reports yet. Share the Chisto app or reporting link with citizens to get started.</p>
        </>
      ) : filteredByStatusCount === 0 ? (
        <>
          <Icon name="document-duplicate" size={40} className={styles.emptyStateIcon} aria-hidden />
          <p>No reports match the selected filter.</p>
        </>
      ) : (
        <>
          <Icon name="magnifying-glass" size={40} className={styles.emptyStateIcon} aria-hidden />
          <p>No reports match &ldquo;{debouncedSearch}&rdquo;.</p>
          <p className={styles.emptyStateHint}>Try a different search term or clear the search.</p>
        </>
      )}
    </div>
  );
}
