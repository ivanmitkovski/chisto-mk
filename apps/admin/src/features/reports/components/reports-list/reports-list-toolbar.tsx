'use client';

import Link from 'next/link';
import { useTranslations } from 'next-intl';
import { Icon, Input } from '@/components/ui';
import styles from '../reports-list.module.css';

type FilterOption = { key: string; label: string };

type ReportsListToolbarProps = {
  isOverview: boolean;
  searchTerm: string;
  onSearchTermChange: (value: string) => void;
  onClearSearch: () => void;
  statusFilters: readonly FilterOption[];
  activeFilter: string;
  onOverviewFilterSelect: (key: string) => void;
  filterHref: (filterKey: string) => string;
};

export function ReportsListToolbar({
  isOverview,
  searchTerm,
  onSearchTermChange,
  onClearSearch,
  statusFilters,
  activeFilter,
  onOverviewFilterSelect,
  filterHref,
}: ReportsListToolbarProps) {
  const t = useTranslations('reports.toolbar');
  const tCommon = useTranslations('common');

  return (
    <div className={styles.toolbar} role="toolbar" aria-label={tCommon('filterAndSearch')}>
      <Input
        aria-label={t('searchAria')}
        placeholder={t('searchPlaceholder')}
        value={searchTerm}
        onChange={(e) => onSearchTermChange(e.target.value)}
        className={styles.search}
        leftSlot={<Icon name="magnifying-glass" size={14} aria-hidden />}
        rightSlot={
          searchTerm ? (
            <button
              type="button"
              className={styles.clearSearchBtn}
              onClick={onClearSearch}
              aria-label={tCommon('clearSearch')}
            >
              <Icon name="x" size={14} aria-hidden />
            </button>
          ) : null
        }
      />
      <div className={styles.filterRow} role="group" aria-label={t('filterByStatusAria')}>
        <div className={styles.filterChips}>
          {statusFilters.map((opt) =>
            isOverview ? (
              <button
                key={opt.key}
                type="button"
                className={`${styles.filterChip} ${activeFilter === opt.key ? styles.filterChipActive : ''}`}
                onClick={() => onOverviewFilterSelect(opt.key)}
                aria-pressed={activeFilter === opt.key}
              >
                {opt.label}
              </button>
            ) : (
              <Link
                key={opt.key}
                href={filterHref(opt.key)}
                className={`${styles.filterChip} ${activeFilter === opt.key ? styles.filterChipActive : ''}`}
                aria-current={activeFilter === opt.key ? 'page' : undefined}
              >
                {opt.label}
              </Link>
            ),
          )}
        </div>
      </div>
    </div>
  );
}
