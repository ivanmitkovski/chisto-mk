'use client';

import { useTranslations } from 'next-intl';
import { Button, Input } from '@/components/ui';
import { USERS_ROLE_OPTIONS, USERS_STATUS_OPTIONS } from '@/features/users/config/users-list-filters';
import styles from './users-workspace.module.css';

type UsersToolbarProps = {
  searchTerm: string;
  role: string;
  status: string;
  onSearchTermChange: (value: string) => void;
  onRoleChange: (value: string) => void;
  onStatusChange: (value: string) => void;
  onRefresh: () => void;
};

export function UsersToolbar({
  searchTerm,
  role,
  status,
  onSearchTermChange,
  onRoleChange,
  onStatusChange,
  onRefresh,
}: UsersToolbarProps) {
  const t = useTranslations('users');
  const tCommon = useTranslations('common');

  return (
    <div className={styles.toolbar}>
      <div className={styles.filters}>
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
      <Button variant="outline" size="sm" onClick={onRefresh}>
        {tCommon('refresh')}
      </Button>
    </div>
  );
}
