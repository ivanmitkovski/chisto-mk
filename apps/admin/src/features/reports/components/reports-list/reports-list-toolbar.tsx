'use client';

import Link from 'next/link';
import { Icon, Input } from '@/components/ui';
import type { SortDirection, SortKey } from '@/features/reports/types';
import { buildReportsUrl } from '../reports-list-utils';
import styles from '../reports-list.module.css';

type FilterOption = { key: string; label: string };

type ReportsListToolbarProps = {
  isOverview: boolean;
  searchTerm: string;
  onSearchTermChange: (value: string) => void;
  onClearSearch: () => void;
  statusFilters: FilterOption[];
  activeFilter: string;
  onOverviewFilterSelect: (key: string) => void;
  sortKey: SortKey;
  sortDirection: SortDirection;
  safePage: number;
};

export function ReportsListToolbar({
  isOverview,
  searchTerm,
  onSearchTermChange,
  onClearSearch,
  statusFilters,
  activeFilter,
  onOverviewFilterSelect,
  sortKey,
  sortDirection,
  safePage,
}: ReportsListToolbarProps) {
  return (
    <div className={styles.toolbar} role="toolbar" aria-label="Filter and search">
      <Input
        aria-label="Search reports by name, location, or number"
        placeholder="Search reports…"
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
              aria-label="Clear search"
            >
              <Icon name="x" size={14} aria-hidden />
            </button>
          ) : null
        }
      />
      <div className={styles.filterRow} role="group" aria-label="Filter by status">
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
                href={buildReportsUrl({
                  status: opt.key !== 'ALL' ? opt.key : undefined,
                  sort: sortKey,
                  dir: sortDirection,
                  page: safePage > 1 ? safePage : undefined,
                })}
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
