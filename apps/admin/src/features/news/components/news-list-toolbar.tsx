'use client';

import { useMemo } from 'react';
import { useTranslations } from 'next-intl';
import {
  Button,
  FilterChipGroup,
  SearchInput,
  Toolbar,
  ToolbarSelect,
} from '@/components/ui';
import {
  NEWS_CATEGORY_FILTERS,
  NEWS_SORT_OPTIONS,
  NEWS_STATUS_FILTERS,
} from '../config/news-list-filters';
import styles from './news-workspace.module.css';

type NewsListToolbarProps = {
  status: string;
  category: string;
  sort: string;
  searchDraft: string;
  hasActiveFilters: boolean;
  isRefreshing?: boolean;
  onSearchDraftChange: (value: string) => void;
  onStatusChange: (value: string) => void;
  onCategoryChange: (value: string) => void;
  onSortChange: (value: string) => void;
  onClearSearch: () => void;
  onClearAllFilters: () => void;
  onRefresh: () => void;
};

export function NewsListToolbar({
  status,
  category,
  sort,
  searchDraft,
  hasActiveFilters,
  isRefreshing = false,
  onSearchDraftChange,
  onStatusChange,
  onCategoryChange,
  onSortChange,
  onClearSearch,
  onClearAllFilters,
  onRefresh,
}: NewsListToolbarProps) {
  const t = useTranslations('news');
  const tCommon = useTranslations('common');

  const statusOptions = useMemo(
    () =>
      NEWS_STATUS_FILTERS.map((value) => ({
        value,
        label: value ? t(`status.${value}` as 'status.draft') : t('toolbar.allStatuses'),
      })),
    [t],
  );

  const categoryOptions = useMemo(
    () =>
      NEWS_CATEGORY_FILTERS.map((value) => ({
        value,
        label: value ? t(`category.${value}` as 'category.release') : t('toolbar.allCategories'),
      })),
    [t],
  );

  const sortOptions = useMemo(
    () =>
      NEWS_SORT_OPTIONS.map((value) => ({
        value,
        label: t(`toolbar.sort_${value}` as 'toolbar.sort_publishedAt'),
      })),
    [t],
  );

  const activeFilterCount = [status, category, searchDraft.trim()].filter(Boolean).length;

  return (
    <div className={styles.toolbarSection}>
      <Toolbar
        className={styles.toolbar}
        activeFilterCount={activeFilterCount}
        aria-label={tCommon('filterAndSearch')}
        end={
          <>
            {hasActiveFilters ? (
              <Button type="button" variant="ghost" size="sm" onClick={onClearAllFilters}>
                {t('toolbar.clearFilters')}
              </Button>
            ) : null}
            <Button
              type="button"
              variant="outline"
              size="sm"
              className={styles.toolbarAction}
              onClick={onRefresh}
              disabled={isRefreshing}
              aria-busy={isRefreshing}
            >
              {isRefreshing ? tCommon('refreshing') : tCommon('refresh')}
            </Button>
          </>
        }
      >
        <div className={styles.toolbarFiltersRow}>
          <SearchInput
            aria-label={t('toolbar.search')}
            placeholder={t('toolbar.searchPlaceholder')}
            value={searchDraft}
            clearLabel={tCommon('clearSearch')}
            onChange={onSearchDraftChange}
            onClear={onClearSearch}
          />
          <ToolbarSelect
            value={sort}
            options={sortOptions}
            aria-label={t('toolbar.sort')}
            className={styles.sortSelect}
            onChange={(e) => onSortChange(e.target.value)}
          />
        </div>
      </Toolbar>

      <div className={styles.filterStrip}>
        <FilterChipGroup
          label={t('toolbar.status')}
          value={status}
          options={statusOptions}
          onChange={onStatusChange}
          nowrap
        />
        <span className={styles.filterStripDivider} aria-hidden />
        <FilterChipGroup
          label={t('toolbar.category')}
          value={category}
          options={categoryOptions}
          onChange={onCategoryChange}
          nowrap
        />
      </div>
    </div>
  );
}
