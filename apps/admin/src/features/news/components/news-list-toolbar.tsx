'use client';

import { useTranslations } from 'next-intl';
import { Button, Input, Select } from '@/components/ui';
import { NEWS_CATEGORY_FILTERS, NEWS_SORT_OPTIONS, NEWS_STATUS_FILTERS } from '../config/news-list-filters';
import styles from './news-list-toolbar.module.css';

type NewsListToolbarProps = {
  status: string;
  category: string;
  sort: string;
  searchDraft: string;
  onSearchDraftChange: (value: string) => void;
  onStatusChange: (value: string) => void;
  onCategoryChange: (value: string) => void;
  onSortChange: (value: string) => void;
  onSearchApply: () => void;
  onRefresh: () => void;
  readOnly?: boolean;
};

export function NewsListToolbar({
  status,
  category,
  sort,
  searchDraft,
  onSearchDraftChange,
  onStatusChange,
  onCategoryChange,
  onSortChange,
  onSearchApply,
  onRefresh,
}: NewsListToolbarProps) {
  const t = useTranslations('news');

  return (
    <div className={styles.root}>
      <div className={styles.filters}>
        <Select
          label={t('toolbar.status')}
          value={status}
          options={NEWS_STATUS_FILTERS.map((s) => ({
            value: s,
            label: s ? t(`status.${s}` as 'status.draft') : t('toolbar.allStatuses'),
          }))}
          onChange={(e) => onStatusChange(e.target.value)}
        />
        <Select
          label={t('toolbar.category')}
          value={category}
          options={NEWS_CATEGORY_FILTERS.map((c) => ({
            value: c,
            label: c ? t(`category.${c}` as 'category.release') : t('toolbar.allCategories'),
          }))}
          onChange={(e) => onCategoryChange(e.target.value)}
        />
        <Select
          label={t('toolbar.sort')}
          value={sort}
          options={NEWS_SORT_OPTIONS.map((s) => ({
            value: s,
            label: t(`toolbar.sort_${s}` as 'toolbar.sort_publishedAt'),
          }))}
          onChange={(e) => onSortChange(e.target.value)}
        />
      </div>
      <div className={styles.searchRow}>
        <Input
          label={t('toolbar.search')}
          value={searchDraft}
          onChange={(e) => onSearchDraftChange(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === 'Enter') onSearchApply();
          }}
          placeholder={t('toolbar.searchPlaceholder')}
        />
        <Button type="button" variant="outline" onClick={onSearchApply}>
          {t('toolbar.searchApply')}
        </Button>
        <Button type="button" variant="ghost" onClick={onRefresh}>
          {t('toolbar.refresh')}
        </Button>
      </div>
    </div>
  );
}
