'use client';

import { useTranslations } from 'next-intl';
import { Button, SearchInput, Toolbar } from '@/components/ui';
import {
  ACTIVE_USERS_PLATFORM_OPTIONS,
  ACTIVE_USERS_STATUS_OPTIONS,
} from '../constants/active-users-filters';
import styles from './active-users-toolbar.module.css';

type ActiveUsersToolbarProps = {
  searchTerm: string;
  status: string;
  platform: string;
  onSearchTermChange: (value: string) => void;
  onStatusChange: (value: string) => void;
  onPlatformChange: (value: string) => void;
};

export function ActiveUsersToolbar({
  searchTerm,
  status,
  platform,
  onSearchTermChange,
  onStatusChange,
  onPlatformChange,
}: ActiveUsersToolbarProps) {
  const t = useTranslations('activeUsers');
  const tCommon = useTranslations('common');

  return (
    <div className={styles.toolbarSection}>
      <Toolbar className={styles.toolbar} aria-label={t('filters.toolbarAria')}>
        <div className={styles.toolbarFiltersRow}>
          <SearchInput
            aria-label={t('filters.searchAria')}
            placeholder={t('filters.searchPlaceholder')}
            value={searchTerm}
            clearLabel={tCommon('clearSearch')}
            onChange={onSearchTermChange}
            className={styles.searchInput}
          />
          <div
            className={styles.statusChips}
            role="group"
            aria-label={t('filters.statusGroupAria')}
          >
            {ACTIVE_USERS_STATUS_OPTIONS.map((opt) => {
              const active = status === opt.value;
              return (
                <Button
                  key={opt.value || 'all'}
                  type="button"
                  size="sm"
                  variant={active ? 'solid' : 'outline'}
                  onClick={() => onStatusChange(opt.value)}
                  aria-pressed={active}
                >
                  {t(opt.labelKey)}
                </Button>
              );
            })}
          </div>
          <select
            value={platform}
            onChange={(e) => onPlatformChange(e.target.value)}
            className={styles.filterSelect}
            aria-label={t('filters.platformLabel')}
          >
            {ACTIVE_USERS_PLATFORM_OPTIONS.map((opt) => (
              <option key={opt.value || 'all'} value={opt.value}>
                {t(opt.labelKey)}
              </option>
            ))}
          </select>
        </div>
      </Toolbar>
    </div>
  );
}
