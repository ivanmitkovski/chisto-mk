'use client';

import Link from 'next/link';
import { useTranslations } from 'next-intl';
import { Button, Input, Toolbar } from '@/components/ui';
import {
  EVENTS_MODERATION_OPTIONS,
  EVENTS_STATUS_OPTIONS,
} from '@/features/events/config/events-list-filters';
import styles from './events-workspace.module.css';

type EventsToolbarProps = {
  status: string;
  moderationStatus: string;
  searchDraft: string;
  canWriteCleanupEvents: boolean;
  isRefreshing?: boolean;
  onStatusChange: (value: string) => void;
  onModerationChange: (value: string) => void;
  onSearchDraftChange: (value: string) => void;
  onSearch: () => void;
  onRefresh: () => void;
};

export function EventsToolbar({
  status,
  moderationStatus,
  searchDraft,
  canWriteCleanupEvents,
  isRefreshing = false,
  onStatusChange,
  onModerationChange,
  onSearchDraftChange,
  onSearch,
  onRefresh,
}: EventsToolbarProps) {
  const t = useTranslations('events');
  const tCommon = useTranslations('common');
  const tNav = useTranslations('nav');

  return (
    <div className={styles.toolbarSection}>
      <div className={styles.toolbarHints}>
        <div className={styles.createHintRow}>
          <Link href="/dashboard/sites" className={styles.createHint}>
            {t('toolbar.createFromSite')}
          </Link>
          <span className={styles.hintDivider} aria-hidden>
            ·
          </span>
          <Link href="/dashboard/events/risk-signals" className={styles.createHint}>
            {tNav('risk-signals')}
          </Link>
        </div>
        {!canWriteCleanupEvents ? (
          <p className={styles.readOnlyHint} role="note">
            {t('readOnlyHint')}
          </p>
        ) : null}
      </div>

      <Toolbar
        className={styles.toolbar}
        end={
          <Button
            variant="outline"
            size="sm"
            type="button"
            className={styles.toolbarAction}
            onClick={onRefresh}
            disabled={isRefreshing}
            aria-busy={isRefreshing}
          >
            {isRefreshing ? tCommon('refreshing') : tCommon('refresh')}
          </Button>
        }
      >
        <div className={styles.toolbarFiltersRow}>
          <select
            value={status}
            onChange={(e) => onStatusChange(e.target.value)}
            className={styles.filterSelect}
            aria-label={t('filters.completionAria')}
          >
            {EVENTS_STATUS_OPTIONS.map((o) => (
              <option key={o.value || '_'} value={o.value}>
                {t(o.labelKey)}
              </option>
            ))}
          </select>
          <select
            value={moderationStatus}
            onChange={(e) => onModerationChange(e.target.value)}
            className={styles.filterSelect}
            aria-label={t('filters.moderationAria')}
          >
            {EVENTS_MODERATION_OPTIONS.map((o) => (
              <option key={o.value || '_'} value={o.value}>
                {t(o.labelKey)}
              </option>
            ))}
          </select>
          <div className={styles.searchGroup}>
            <div className={styles.searchFieldWrap}>
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
                placeholder={t('filters.searchPlaceholder')}
                className={styles.searchInput}
                aria-label={t('filters.searchAria')}
              />
            </div>
            <Button
              variant="outline"
              size="sm"
              type="button"
              className={styles.toolbarAction}
              onClick={onSearch}
            >
              {tCommon('search')}
            </Button>
          </div>
        </div>
      </Toolbar>
    </div>
  );
}
