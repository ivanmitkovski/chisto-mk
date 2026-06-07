'use client';

import { useRouter, useSearchParams } from 'next/navigation';
import { useCallback } from 'react';
import { useTranslations } from 'next-intl';
import { Checkbox, DropdownMenu, Icon, Input } from '@/components/ui';
import { MAP_STATUS_FILTER_OPTIONS } from '@/features/map/config/map-status-filters';
import { MAP_SITE_FETCH_LIMIT } from '../map-constants';
import styles from './sites-map.module.css';

type MapToolbarProps = {
  statusFilter: string;
  onStatusChange: (status: string) => void;
  onFitBounds: () => void;
  onRefresh: () => void;
  includeArchived: boolean;
  onIncludeArchivedChange: (value: boolean) => void;
  showHeatmap: boolean;
  onHeatmapChange: (value: boolean) => void;
  searchDraft: string;
  onSearchDraftChange: (value: string) => void;
  onSearch: () => void;
  searchMessage: string | null;
  resultCapped: boolean;
};

export function MapToolbar({
  statusFilter,
  onStatusChange,
  onFitBounds,
  onRefresh,
  includeArchived,
  onIncludeArchivedChange,
  showHeatmap,
  onHeatmapChange,
  searchDraft,
  onSearchDraftChange,
  onSearch,
  searchMessage,
  resultCapped,
}: MapToolbarProps) {
  const t = useTranslations('map');
  const tCommon = useTranslations('common');
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
    <div className={styles.toolbarStack}>
      {resultCapped ? (
        <p className={styles.mapCapWarning} role="status">
          {t('capWarning', { limit: MAP_SITE_FETCH_LIMIT })}
        </p>
      ) : null}
      <div
        className={styles.toolbar}
        role="toolbar"
        aria-label={t('toolbarAria')}
        onWheelCapture={(e) => e.stopPropagation()}
        onDoubleClickCapture={(e) => e.stopPropagation()}
      >
        <div className={styles.toolbarLeading}>
          <div className={styles.statusChips} role="group" aria-label={t('statusFilterGroupAria')}>
            {MAP_STATUS_FILTER_OPTIONS.map(({ value, labelKey }) => (
              <button
                key={value || 'all'}
                type="button"
                className={`${styles.chip} ${statusFilter === value ? styles.chipActive : ''}`}
                onClick={() => handleStatusClick(value)}
                aria-pressed={statusFilter === value}
              >
                {t(labelKey)}
              </button>
            ))}
          </div>
        </div>
        <div className={styles.toolbarTrailing}>
          <div className={styles.mapSearchGroup}>
            <Input
              type="search"
              value={searchDraft}
              onChange={(e) => onSearchDraftChange(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === 'Enter') {
                  e.preventDefault();
                  onSearch();
                }
              }}
              placeholder={t('searchPlaceholder')}
              aria-label={t('searchAria')}
              className={styles.mapSearchInput}
            />
            <button type="button" className={styles.toolbarBtn} onClick={onSearch}>
              <Icon name="magnifying-glass" size={16} aria-hidden />
              <span className={styles.toolbarBtnLabel}>{tCommon('search')}</span>
            </button>
          </div>
          <DropdownMenu
            label={t('viewOptions')}
            aria-label={t('viewOptionsAria')}
            panelAriaLabel={t('viewOptionsPanelAria')}
            icon="sliders"
            active={includeArchived || showHeatmap}
            align="end"
            compact
            menuRole={false}
            triggerClassName={styles.toolbarBtn}
          >
            <div className={styles.viewOptionsPanel}>
              <Checkbox
                checked={includeArchived}
                onChange={(e) => onIncludeArchivedChange(e.target.checked)}
                label={t('showArchived')}
                labelAlign="start"
              />
              <Checkbox
                checked={showHeatmap}
                onChange={(e) => onHeatmapChange(e.target.checked)}
                label={t('heatmap')}
                labelAlign="start"
              />
            </div>
          </DropdownMenu>
          <div className={styles.toolbarDivider} aria-hidden />
          <div className={styles.toolbarActions}>
            <button
              type="button"
              className={styles.toolbarBtn}
              onClick={onFitBounds}
              aria-label={t('fitBoundsAria')}
            >
              <Icon name="location" size={16} aria-hidden />
              <span className={styles.toolbarBtnLabel}>{t('fitBounds')}</span>
            </button>
            <button
              type="button"
              className={styles.toolbarBtn}
              onClick={onRefresh}
              aria-label={t('refreshAria')}
            >
              <Icon name="refresh" size={16} aria-hidden />
              <span className={styles.toolbarBtnLabel}>{tCommon('refresh')}</span>
            </button>
          </div>
        </div>
      </div>
      {searchMessage ? <p className={styles.mapSearchMessage}>{searchMessage}</p> : null}
    </div>
  );
}
