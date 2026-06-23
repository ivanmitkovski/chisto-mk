'use client';

import { useMemo } from 'react';
import Link from 'next/link';
import { useTranslations } from 'next-intl';
import {
  Avatar,
  Card,
  DataTable,
  DataTableLink,
  DataTableMobileField,
  Pagination,
  SectionState,
  Button,
  type DataTableColumn,
} from '@/components/ui';
import { formatAdminDateTime, useAdminBcp47Locale } from '@/lib/i18n';
import type { ActiveUserRow } from '../data/active-users.types';
import { ACTIVE_USERS_PAGE_SIZE } from '../constants/active-users-filters';
import { useActiveUsersLive } from '../hooks/use-active-users-live';
import styles from './active-users-table.module.css';

function formatDuration(seconds: number): string {
  if (seconds < 60) return `${seconds}s`;
  const mins = Math.floor(seconds / 60);
  if (mins < 60) return `${mins}m`;
  const hours = Math.floor(mins / 60);
  return `${hours}h ${mins % 60}m`;
}

type ActiveUsersTableProps = {
  page: number;
  onPageChange: (page: number) => void;
};

export function ActiveUsersTable({ page, onPageChange }: ActiveUsersTableProps) {
  const t = useTranslations('activeUsers');
  const locale = useAdminBcp47Locale();
  const { rows, listTotal, listError, refresh } = useActiveUsersLive();

  const deviceCountByUser = useMemo(() => {
    const map = new Map<string, number>();
    for (const row of rows) {
      map.set(row.userId, (map.get(row.userId) ?? 0) + 1);
    }
    return map;
  }, [rows]);

  const statusClass = (status: string) => {
    if (status === 'online') return styles.statusOnline;
    if (status === 'away') return styles.statusAway;
    return styles.statusOffline;
  };

  const columns: DataTableColumn<ActiveUserRow>[] = [
    {
      key: 'user',
      header: t('user'),
      render: (row) => {
        const name = `${row.firstName} ${row.lastName}`.trim() || row.email;
        const devices = deviceCountByUser.get(row.userId) ?? 1;
        return (
          <div className={styles.userCell}>
            <Avatar name={name} imageUrl={row.avatarUrl ?? null} size="sm" />
            <div className={styles.userMeta}>
              <DataTableLink href={`/dashboard/users/${row.userId}?tab=activity`}>
                {name}
              </DataTableLink>
              <span className={styles.sub}>{row.email}</span>
              {devices > 1 ? (
                <span className={styles.deviceBadge}>{t('devicesCount', { count: devices })}</span>
              ) : null}
            </div>
          </div>
        );
      },
    },
    {
      key: 'status',
      header: t('statusLabel'),
      render: (row) => (
        <span className={`${styles.statusPill} ${statusClass(row.status)}`}>
          {t(`status.${row.status}`)}
        </span>
      ),
    },
    {
      key: 'screen',
      header: t('screen'),
      render: (row) => row.currentScreen ?? '—',
    },
    {
      key: 'platform',
      header: t('platformLabel'),
      render: (row) =>
        row.platform
          ? `${row.platform}${row.appVersion ? ` (${row.appVersion})` : ''}`
          : '—',
    },
    {
      key: 'device',
      header: t('deviceModel'),
      render: (row) => row.deviceModel ?? '—',
    },
    {
      key: 'location',
      header: t('location'),
      render: (row) => [row.city, row.country].filter(Boolean).join(', ') || '—',
    },
    {
      key: 'session',
      header: t('sessionDuration'),
      render: (row) => formatDuration(row.sessionDurationSeconds),
    },
    {
      key: 'lastActivity',
      header: t('lastActivity'),
      render: (row) =>
        formatAdminDateTime(row.lastActivity, locale, { hour: '2-digit', minute: '2-digit' }),
    },
  ];

  if (listError) {
    return (
      <Card padding="md">
        <SectionState variant="error" message={t('errors.listFailed')}>
          <Button type="button" variant="outline" size="sm" onClick={() => refresh()}>
            {t('retry')}
          </Button>
        </SectionState>
      </Card>
    );
  }

  if (rows.length === 0) {
    return (
      <Card padding="md">
        <SectionState variant="empty" message={t('noActiveUsers')} />
      </Card>
    );
  }

  const totalPages = Math.max(1, Math.ceil(listTotal / ACTIVE_USERS_PAGE_SIZE));

  return (
    <Card padding="sm" className={styles.card}>
      <DataTable
        columns={columns}
        data={rows}
        getRowId={(row) => row.id}
        renderMobileCard={(row) => {
          const name = `${row.firstName} ${row.lastName}`.trim() || row.email;
          return (
            <div className={styles.mobileCard}>
              <DataTableMobileField label={t('user')}>
                <Link href={`/dashboard/users/${row.userId}?tab=activity`}>{name}</Link>
              </DataTableMobileField>
              <DataTableMobileField label={t('statusLabel')}>
                {t(`status.${row.status}`)}
              </DataTableMobileField>
              <DataTableMobileField label={t('screen')}>
                {row.currentScreen ?? '—'}
              </DataTableMobileField>
              <DataTableMobileField label={t('lastActivity')}>
                {formatAdminDateTime(row.lastActivity, locale)}
              </DataTableMobileField>
            </div>
          );
        }}
        pagination={
          totalPages > 1 ? (
            <div className={styles.pagination}>
              <Pagination
                totalPages={totalPages}
                currentPage={page}
                onPageChange={onPageChange}
              />
            </div>
          ) : undefined
        }
      />
    </Card>
  );
}
