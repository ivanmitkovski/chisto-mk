'use client';

import { useTranslations } from 'next-intl';
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
  const t = useTranslations('reports');

  return (
    <div className={styles.emptyState}>
      {totalReportsCount === 0 ? (
        <>
          <Icon name="document-text" size={40} className={styles.emptyStateIcon} aria-hidden />
          <p>{t('emptyStates.noReportsYet')}</p>
        </>
      ) : filteredByStatusCount === 0 ? (
        <>
          <Icon name="document-duplicate" size={40} className={styles.emptyStateIcon} aria-hidden />
          <p>{t('emptyStates.noFilterMatch')}</p>
        </>
      ) : (
        <>
          <Icon name="magnifying-glass" size={40} className={styles.emptyStateIcon} aria-hidden />
          <p>{t('emptyStates.noSearchMatch', { query: debouncedSearch })}</p>
          <p className={styles.emptyStateHint}>{t('emptyStates.searchHint')}</p>
        </>
      )}
    </div>
  );
}
