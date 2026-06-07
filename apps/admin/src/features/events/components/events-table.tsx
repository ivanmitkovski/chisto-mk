'use client';

import Link from 'next/link';
import { useTranslations } from 'next-intl';
import {
  Checkbox,
  DataTable,
  DataTableLink,
  DataTableMobileField,
  type DataTableColumn,
} from '@/components/ui';
import type { CleanupEventRow } from '@/features/events/data/events-adapter';
import { formatEventDateTime, mapSiteLinks } from '@/features/events/lib/events-display';
import styles from './events-workspace.module.css';

type EventsTableProps = {
  data: CleanupEventRow[];
  showModerationBulk: boolean;
  selectedIds: Set<string>;
  onToggleSelected: (id: string) => void;
};

function SiteCell({ row }: { row: CleanupEventRow }) {
  const tCommon = useTranslations('common');
  const { gm, am } = mapSiteLinks(row.site.latitude, row.site.longitude);
  return (
    <div className={styles.siteCell}>
      <Link href={`/dashboard/sites/${row.site.id}`} className={styles.siteLink}>
        {row.site.latitude.toFixed(5)}, {row.site.longitude.toFixed(5)}
      </Link>
      <div className={styles.mapLinks}>
        <a href={gm} target="_blank" rel="noopener noreferrer" className={styles.mapLink}>
          {tCommon('googleMaps')}
        </a>
        <span className={styles.mapDivider}>·</span>
        <a href={am} target="_blank" rel="noopener noreferrer" className={styles.mapLink}>
          {tCommon('appleMaps')}
        </a>
      </div>
      {row.site.description ? <p className={styles.siteDesc}>{row.site.description}</p> : null}
    </div>
  );
}

function StatusCell({ row }: { row: CleanupEventRow }) {
  const t = useTranslations('events');
  const isCompleted = !!row.completedAt;
  const modStatus = row.status ?? 'APPROVED';
  return (
    <div className={styles.statusCell}>
      <span className={isCompleted ? styles.statusCompleted : styles.statusUpcoming}>
        {isCompleted ? t('table.completed') : t('table.upcoming')}
      </span>
      <span
        className={
          modStatus === 'PENDING'
            ? styles.modStatusPending
            : modStatus === 'DECLINED'
              ? styles.modStatusDeclined
              : styles.modStatusApproved
        }
      >
        {modStatus}
      </span>
    </div>
  );
}

export function EventsTable({
  data,
  showModerationBulk,
  selectedIds,
  onToggleSelected,
}: EventsTableProps) {
  const t = useTranslations('events');
  const tCommon = useTranslations('common');

  const bulkColumn: DataTableColumn<CleanupEventRow> = {
    key: 'select',
    header: t('table.select'),
    mobileHidden: true,
    renderHeader: () => <span className={styles.srOnly}>{t('table.select')}</span>,
    render: (e) => (
      <Checkbox
        checked={selectedIds.has(e.id)}
        onChange={() => onToggleSelected(e.id)}
        aria-label={t('table.selectEventAria', { title: e.title })}
      />
    ),
  };

  const columns: DataTableColumn<CleanupEventRow>[] = [
    ...(showModerationBulk ? [bulkColumn] : []),
    {
      key: 'title',
      header: t('table.title'),
      render: (e) => (
        <Link href={`/dashboard/events/${e.id}`} className={styles.titleLink}>
          {e.title || t('untitled')}
        </Link>
      ),
    },
    {
      key: 'scheduled',
      header: t('table.scheduled'),
      render: (e) => <span className={styles.cellDateTime}>{formatEventDateTime(e.scheduledAt)}</span>,
    },
    {
      key: 'site',
      header: t('table.site'),
      render: (e) => <SiteCell row={e} />,
    },
    {
      key: 'participants',
      header: t('table.participants'),
      render: (e) => e.participantCount,
    },
    {
      key: 'status',
      header: t('table.status'),
      render: (e) => <StatusCell row={e} />,
    },
    {
      key: 'completed',
      header: t('table.completed'),
      render: (e) => (
        <span className={styles.cellDateTime}>
          {e.completedAt ? formatEventDateTime(e.completedAt) : '—'}
        </span>
      ),
    },
    {
      key: 'actions',
      header: tCommon('viewDetails'),
      render: (e) => (
        <DataTableLink href={`/dashboard/events/${e.id}`}>{tCommon('viewDetails')}</DataTableLink>
      ),
    },
  ];

  return (
    <DataTable
      columns={columns}
      data={data}
      getRowId={(e) => e.id}
      emptyMessage={t('table.empty')}
      tableClassName={
        showModerationBulk ? `${styles.table} ${styles.tableWithBulk}` : styles.table
      }
      renderMobileCard={(e) => {
        const isCompleted = !!e.completedAt;
        const modStatus = e.status ?? 'APPROVED';
        return (
          <>
            {showModerationBulk ? (
              <div className={styles.mobileCardHeader}>
                <Checkbox
                  checked={selectedIds.has(e.id)}
                  onChange={() => onToggleSelected(e.id)}
                  aria-label={t('table.selectEventAria', { title: e.title })}
                />
                <span className={styles.mobileCardTitle}>
                  {formatEventDateTime(e.scheduledAt)}
                </span>
              </div>
            ) : (
              <p className={styles.mobileCardTitle}>
                <Link href={`/dashboard/events/${e.id}`} className={styles.titleLink}>
                  {e.title || t('untitled')}
                </Link>
              </p>
            )}
            <DataTableMobileField label={t('table.scheduled')}>
              {formatEventDateTime(e.scheduledAt)}
            </DataTableMobileField>
            <DataTableMobileField label={t('table.site')}>
              <SiteCell row={e} />
            </DataTableMobileField>
            <DataTableMobileField label={t('table.participants')}>{e.participantCount}</DataTableMobileField>
            <DataTableMobileField label={t('table.status')}>
              <div className={styles.statusCell}>
                <span className={isCompleted ? styles.statusCompleted : styles.statusUpcoming}>
                  {isCompleted ? t('table.completed') : t('table.upcoming')}
                </span>
                <span
                  className={
                    modStatus === 'PENDING'
                      ? styles.modStatusPending
                      : modStatus === 'DECLINED'
                        ? styles.modStatusDeclined
                        : styles.modStatusApproved
                  }
                >
                  {modStatus}
                </span>
              </div>
            </DataTableMobileField>
            <DataTableMobileField label={t('table.completed')}>
              {e.completedAt ? formatEventDateTime(e.completedAt) : '—'}
            </DataTableMobileField>
            <div className={styles.mobileCardActions}>
              <DataTableLink href={`/dashboard/events/${e.id}`}>{tCommon('viewDetails')}</DataTableLink>
            </div>
          </>
        );
      }}
    />
  );
}
