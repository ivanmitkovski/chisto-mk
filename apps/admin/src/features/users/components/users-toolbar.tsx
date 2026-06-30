'use client';

import Link from 'next/link';
import { useTranslations } from 'next-intl';
import { Button, DatePicker, Input, Toolbar } from '@/components/ui';
import { USERS_QUICK_STATUS_FILTERS, USERS_ROLE_OPTIONS, USERS_STATUS_OPTIONS } from '@/features/users/config/users-list-filters';
import type { UsersQuickFilter } from '@/features/users/hooks/use-users-list-url';
import styles from './users-workspace.module.css';

type UsersToolbarProps = {
  searchTerm: string;
  role: string;
  status: string;
  quickFilter: UsersQuickFilter;
  draftLastActiveBefore: string;
  draftLastActiveAfter: string;
  isRefreshing?: boolean;
  onSearchTermChange: (value: string) => void;
  onRoleChange: (value: string) => void;
  onStatusChange: (value: string) => void;
  onQuickFilter: (value: UsersQuickFilter) => void;
  onDraftLastActiveBeforeChange: (value: string) => void;
  onDraftLastActiveAfterChange: (value: string) => void;
  onApplyLastActiveFilters: () => void;
  onClearLastActiveFilters: () => void;
  onRefresh: () => void;
  onExportCsv: () => void;
  exporting?: boolean;
};

export function UsersToolbar({
  searchTerm,
  role,
  status,
  quickFilter,
  draftLastActiveBefore,
  draftLastActiveAfter,
  isRefreshing = false,
  onSearchTermChange,
  onRoleChange,
  onStatusChange,
  onQuickFilter,
  onDraftLastActiveBeforeChange,
  onDraftLastActiveAfterChange,
  onApplyLastActiveFilters,
  onClearLastActiveFilters,
  onRefresh,
  onExportCsv,
  exporting = false,
}: UsersToolbarProps) {
  const t = useTranslations('users');
  const tCommon = useTranslations('common');
  const tUi = useTranslations('ui');

  const lastActiveFiltersDirty =
    draftLastActiveBefore !== '' || draftLastActiveAfter !== '';

  return (
    <div className={styles.toolbarSection}>
      <div className={styles.quickFilters} role="group" aria-label={t('filters.quickFiltersAria')}>
        {USERS_QUICK_STATUS_FILTERS.map((chip) => {
          const active = quickFilter === chip.value;
          return (
            <Button
              key={chip.value || 'all'}
              type="button"
              size="sm"
              variant={active ? 'solid' : 'outline'}
              onClick={() => onQuickFilter(chip.value)}
              aria-pressed={active}
            >
              {t(chip.labelKey)}
            </Button>
          );
        })}
      </div>

      <Toolbar
        className={styles.toolbar}
        end={
          <>
            <Button
              variant="outline"
              size="sm"
              type="button"
              onClick={onExportCsv}
              disabled={exporting}
              aria-busy={exporting}
            >
              {exporting ? tCommon('exporting') : tCommon('exportCsv')}
            </Button>
            <Button
              variant="outline"
              size="sm"
              type="button"
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
          <Input
            type="search"
            placeholder={t('filters.searchPlaceholder')}
            value={searchTerm}
            onChange={(e) => onSearchTermChange(e.target.value)}
            className={styles.searchInput}
            aria-label={t('filters.searchAria')}
          />
          <select
            value={role}
            onChange={(e) => onRoleChange(e.target.value)}
            className={styles.filterSelect}
            aria-label={t('filters.filterByRole')}
          >
            {USERS_ROLE_OPTIONS.map((o) => (
              <option key={o.value || '_'} value={o.value}>
                {t(o.labelKey)}
              </option>
            ))}
          </select>
          <select
            value={status}
            onChange={(e) => onStatusChange(e.target.value)}
            className={styles.filterSelect}
            aria-label={t('filters.filterByStatus')}
          >
            {USERS_STATUS_OPTIONS.map((o) => (
              <option key={o.value || '_'} value={o.value}>
                {t(o.labelKey)}
              </option>
            ))}
          </select>
        </div>
      </Toolbar>

      <div className={styles.lastActiveRow}>
        <span className={styles.lastActiveLabel}>{t('filters.lastActiveRange')}</span>
        <div className={styles.lastActiveFields}>
          <div className={styles.lastActiveRangeGroup}>
            <div className={styles.lastActivePicker}>
              <DatePicker
                size="sm"
                hideLabel
                label={t('filters.lastActiveAfter')}
                value={draftLastActiveAfter}
                onValueChange={onDraftLastActiveAfterChange}
              />
            </div>
            <span className={styles.lastActiveSep} aria-hidden>
              –
            </span>
            <div className={styles.lastActivePicker}>
              <DatePicker
                size="sm"
                hideLabel
                label={t('filters.lastActiveBefore')}
                value={draftLastActiveBefore}
                onValueChange={onDraftLastActiveBeforeChange}
              />
            </div>
          </div>
        </div>
        <div className={styles.lastActiveActions}>
          <Button
            type="button"
            size="sm"
            onClick={onApplyLastActiveFilters}
            disabled={!lastActiveFiltersDirty}
          >
            {tUi('applyFilters')}
          </Button>
          {lastActiveFiltersDirty ? (
            <Button type="button" size="sm" variant="outline" onClick={onClearLastActiveFilters}>
              {tCommon('clear')}
            </Button>
          ) : null}
        </div>
        <Link href="/dashboard/active-users" className={styles.toolbarHintLink}>
          {t('filters.viewActiveUsers')}
        </Link>
      </div>
    </div>
  );
}
