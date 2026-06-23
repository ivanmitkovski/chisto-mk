'use client';

import type { RefObject } from 'react';
import { useTranslations } from 'next-intl';
import {
  Checkbox,
  DataTable,
  DataTableLink,
  DataTableMobileField,
  type DataTableColumn,
} from '@/components/ui';
import type { UserRow } from '@/features/users/data/users-adapter';
import type { UsersSortDir, UsersSortKey } from '@/features/users/config/users-list-sort';
import { formatAdminDateTime, useAdminBcp47Locale } from '@/lib/i18n';
import styles from './users-workspace.module.css';

function formatDate(value: string | null, locale: string): string {
  if (!value) return '—';
  return formatAdminDateTime(value, locale);
}

function formatToken(value: string): string {
  return value
    .replace(/_/g, ' ')
    .toLowerCase()
    .replace(/\b\w/g, (char) => char.toUpperCase());
}

const ROLE_LABEL_KEY_BY_VALUE: Record<string, string> = {
  USER: 'filters.roleUser',
  SUPPORT: 'filters.roleSupport',
  ADMIN: 'filters.roleAdmin',
  SUPER_ADMIN: 'filters.roleSuperAdmin',
};

const STATUS_LABEL_KEY_BY_VALUE: Record<string, string> = {
  ACTIVE: 'filters.active',
  SUSPENDED: 'filters.suspended',
  DELETED: 'filters.deleted',
};

function resolveUserDisplayName(
  u: UserRow,
  deletedLabel: string,
): string {
  if (u.status === 'DELETED') {
    return deletedLabel;
  }
  return `${u.firstName} ${u.lastName}`.trim();
}

function statusPillClass(status: string): string {
  const map: Record<string, string> = {
    ACTIVE: styles.statusActive,
    SUSPENDED: styles.statusSuspended,
    DELETED: styles.statusDeleted,
  };
  return `${styles.statusPill} ${map[status] ?? styles.statusDefault}`;
}

function rolePillClass(role: string): string {
  const map: Record<string, string> = {
    ADMIN: styles.roleAdmin,
    SUPER_ADMIN: styles.roleSuperAdmin,
    SUPPORT: styles.roleSupport,
    USER: styles.roleUser,
  };
  return `${styles.rolePill} ${map[role] ?? styles.roleDefault}`;
}

type UsersTableProps = {
  data: UserRow[];
  canBulk: boolean;
  highlightedUserIds?: Set<string>;
  selectedIds: Set<string>;
  allSelected: boolean;
  selectAllRef: RefObject<HTMLInputElement | null>;
  onToggleAll: () => void;
  onToggleSelection: (id: string) => void;
  sortKey: UsersSortKey;
  sortDir: UsersSortDir;
  onSort: (key: string) => void;
};

export function UsersTable({
  data,
  canBulk,
  highlightedUserIds = new Set(),
  selectedIds,
  allSelected,
  selectAllRef,
  onToggleAll,
  onToggleSelection,
  sortKey,
  sortDir,
  onSort,
}: UsersTableProps) {
  const t = useTranslations('users');
  const tCommon = useTranslations('common');
  const locale = useAdminBcp47Locale();
  const roleLabel = (role: string) => {
    const labelKey = ROLE_LABEL_KEY_BY_VALUE[role];
    return labelKey ? t(labelKey) : formatToken(role);
  };
  const statusLabel = (status: string) => {
    const labelKey = STATUS_LABEL_KEY_BY_VALUE[status];
    return labelKey ? t(labelKey) : formatToken(status);
  };
  const userDisplayName = (u: UserRow) => resolveUserDisplayName(u, t('deletedUser'));

  const bulkColumn: DataTableColumn<UserRow> = {
    key: 'select',
    header: '',
    mobileHidden: true,
    renderHeader: () => (
      <Checkbox
        ref={selectAllRef}
        checked={allSelected}
        onChange={onToggleAll}
        aria-label={t('table.selectAllAria')}
      />
    ),
    render: (u) => (
      <Checkbox
        checked={selectedIds.has(u.id)}
        onChange={() => onToggleSelection(u.id)}
        aria-label={t('table.selectUserAria', { name: userDisplayName(u) })}
      />
    ),
  };

  const columns: DataTableColumn<UserRow>[] = [
    ...(canBulk ? [bulkColumn] : []),
    {
      key: 'name',
      header: t('table.name'),
      sortable: true,
      render: (u) => (
        <DataTableLink href={`/dashboard/users/${u.id}`}>
          {userDisplayName(u)}
        </DataTableLink>
      ),
    },
    {
      key: 'email',
      header: t('table.email'),
      sortable: true,
      render: (u) => u.email,
    },
    {
      key: 'phone',
      header: t('table.phone'),
      render: (u) => u.phoneNumber || '—',
    },
    {
      key: 'role',
      header: t('table.role'),
      render: (u) => <span className={rolePillClass(u.role)}>{roleLabel(u.role)}</span>,
    },
    {
      key: 'status',
      header: t('table.status'),
      render: (u) => <span className={statusPillClass(u.status)}>{statusLabel(u.status)}</span>,
    },
    {
      key: 'lastActiveAt',
      header: t('table.lastActive'),
      sortable: true,
      render: (u) => formatDate(u.lastActiveAt, locale),
    },
    {
      key: 'createdAt',
      header: t('table.created'),
      sortable: true,
      render: (u) => formatDate(u.createdAt, locale),
    },
    {
      key: 'pointsBalance',
      header: t('table.points'),
      sortable: true,
      render: (u) => u.pointsBalance,
    },
    {
      key: 'actions',
      header: tCommon('viewDetails'),
      render: (u) => (
        <DataTableLink href={`/dashboard/users/${u.id}`}>{tCommon('viewDetails')}</DataTableLink>
      ),
    },
  ];

  return (
    <DataTable
      columns={columns}
      data={data}
      getRowId={(u) => u.id}
      emptyMessage={t('table.empty')}
      tableClassName={canBulk ? `${styles.table} ${styles.tableWithBulk}` : styles.table}
      sortKey={sortKey}
      sortDir={sortDir}
      onSort={onSort}
      getRowClassName={(u) => {
        const classes: string[] = [];
        if (selectedIds.has(u.id)) classes.push(styles.rowSelected);
        if (highlightedUserIds.has(u.id)) classes.push(styles.rowHighlighted);
        return classes.length > 0 ? classes.join(' ') : undefined;
      }}
      getMobileCardClassName={(u) => {
        const classes: string[] = [];
        if (selectedIds.has(u.id)) classes.push(styles.mobileCardSelected);
        if (highlightedUserIds.has(u.id)) classes.push(styles.rowHighlighted);
        return classes.length > 0 ? classes.join(' ') : undefined;
      }}
      renderMobileCard={(u) => (
        <>
          <div className={styles.mobileCardHeader}>
            {canBulk ? (
              <Checkbox
                checked={selectedIds.has(u.id)}
                onChange={() => onToggleSelection(u.id)}
                aria-label={t('table.selectUserAria', { name: userDisplayName(u) })}
              />
            ) : null}
            <DataTableLink href={`/dashboard/users/${u.id}`}>
              {userDisplayName(u)}
            </DataTableLink>
          </div>
          <DataTableMobileField label={t('table.email')}>{u.email}</DataTableMobileField>
          <DataTableMobileField label={t('table.phone')}>{u.phoneNumber || '—'}</DataTableMobileField>
          <DataTableMobileField label={t('table.role')}>
            <span className={rolePillClass(u.role)}>{roleLabel(u.role)}</span>
          </DataTableMobileField>
          <DataTableMobileField label={t('table.status')}>
            <span className={statusPillClass(u.status)}>{statusLabel(u.status)}</span>
          </DataTableMobileField>
          <DataTableMobileField label={t('table.lastActive')}>
            {formatDate(u.lastActiveAt, locale)}
          </DataTableMobileField>
          <DataTableMobileField label={t('table.created')}>
            {formatDate(u.createdAt, locale)}
          </DataTableMobileField>
          <DataTableMobileField label={t('table.points')}>{u.pointsBalance}</DataTableMobileField>
          <div className={styles.mobileCardActions}>
            <DataTableLink href={`/dashboard/users/${u.id}`}>{t('detail.viewProfile')}</DataTableLink>
          </div>
        </>
      )}
    />
  );
}
