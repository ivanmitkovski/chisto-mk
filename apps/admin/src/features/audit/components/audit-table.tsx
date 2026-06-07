'use client';

import { useTranslations } from 'next-intl';
import {
  DataTable,
  DataTableLink,
  DataTableMobileField,
  MetadataView,
  type DataTableColumn,
} from '@/components/ui';
import type { AuditRow } from '@/features/audit/data/audit-adapter';
import { formatAdminDateTime, useAdminBcp47Locale } from '@/lib/i18n';
import styles from './audit-workspace.module.css';

function formatAction(action: string): string {
  return action.replace(/_/g, ' ').toLowerCase().replace(/\b\w/g, (c) => c.toUpperCase());
}

function actionPillClass(action: string): string {
  if (action.includes('LOGIN')) return styles.pillAuth;
  if (action.includes('CREATED') || action.includes('CREATE')) return styles.pillCreate;
  if (action.includes('UPDATED') || action.includes('UPDATE')) return styles.pillUpdate;
  if (action.includes('DELETED') || action.includes('DELETE') || action.includes('REJECT'))
    return styles.pillDelete;
  if (action.includes('MERGE')) return styles.pillMerge;
  if (action.includes('REVOKE') || action.includes('FAILED')) return styles.pillWarning;
  return styles.pillDefault;
}

function resourceHref(row: AuditRow): string | null {
  if (!row.resourceId) return null;
  switch (row.resourceType) {
    case 'User':
      return `/dashboard/users/${row.resourceId}`;
    case 'Report':
      return `/dashboard/reports/${row.resourceId}`;
    case 'Site':
      return `/dashboard/sites/${row.resourceId}`;
    case 'CleanupEvent':
      return `/dashboard/events/${row.resourceId}`;
    default:
      return null;
  }
}

function truncateId(id: string | null, max = 12): string {
  if (!id) return '—';
  if (id.length <= max) return id;
  return `${id.slice(0, 6)}…${id.slice(-4)}`;
}

function ResourceCell({
  row,
  onCopyId,
  copyIdTitle,
}: {
  row: AuditRow;
  onCopyId: (id: string) => void;
  copyIdTitle: string;
}) {
  const href = resourceHref(row);
  return (
    <div className={styles.resourceCell}>
      <span className={styles.resourceType}>{row.resourceType}</span>
      {row.resourceId && (
        <>
          <span className={styles.resourceSep}>·</span>
          {href ? (
            <DataTableLink href={href}>{truncateId(row.resourceId)}</DataTableLink>
          ) : (
            <button
              type="button"
              className={styles.resourceIdBtn}
              onClick={() => onCopyId(row.resourceId!)}
              title={copyIdTitle}
            >
              {truncateId(row.resourceId)}
            </button>
          )}
        </>
      )}
    </div>
  );
}

type AuditTableProps = {
  data: AuditRow[];
  expandedId: string | null;
  onToggleExpanded: (id: string) => void;
  onCopyId: (id: string) => void;
};

export function AuditTable({ data, expandedId, onToggleExpanded, onCopyId }: AuditTableProps) {
  const t = useTranslations('audit');
  const locale = useAdminBcp47Locale();

  const columns: DataTableColumn<AuditRow>[] = [
    {
      key: 'time',
      header: t('table.time'),
      render: (row) => (
        <span className={styles.cellTime}>
          {formatAdminDateTime(row.createdAt, locale)}
        </span>
      ),
    },
    {
      key: 'action',
      header: t('table.action'),
      render: (row) => (
        <span className={actionPillClass(row.action)}>{formatAction(row.action)}</span>
      ),
    },
    {
      key: 'resource',
      header: t('table.resource'),
      render: (row) => <ResourceCell row={row} onCopyId={onCopyId} copyIdTitle={t('table.copyId')} />,
    },
    {
      key: 'actor',
      header: t('table.actor'),
      render: (row) => (
        <span className={styles.actor}>{row.actorEmail ?? <em>{t('table.system')}</em>}</span>
      ),
    },
    {
      key: 'details',
      header: '',
      render: (row) => {
        const hasMetadata = row.metadata != null;
        const isExpanded = expandedId === row.id;
        if (!hasMetadata) return null;
        return (
          <button
            type="button"
            className={styles.detailsBtn}
            onClick={() => onToggleExpanded(row.id)}
            aria-expanded={isExpanded}
          >
            {isExpanded ? t('table.hide') : t('table.details')}
          </button>
        );
      },
    },
  ];

  return (
    <DataTable
      columns={columns}
      data={data}
      getRowId={(row) => row.id}
      emptyMessage={t('table.empty')}
      tableClassName={styles.table}
      renderAfterRow={(row) => {
        const isExpanded = expandedId === row.id;
        const hasMetadata = row.metadata != null;
        if (!isExpanded || !hasMetadata) return null;
        return (
          <tr className={styles.metaRow}>
            <td colSpan={columns.length}>
              <MetadataView value={row.metadata} variant="block" />
            </td>
          </tr>
        );
      }}
      renderMobileCard={(row) => {
        const hasMetadata = row.metadata != null;
        const isExpanded = expandedId === row.id;
        return (
          <>
            <p className={styles.mobileCardTime}>
              {formatAdminDateTime(row.createdAt, locale)}
            </p>
            <DataTableMobileField label={t('table.action')}>
              <span className={actionPillClass(row.action)}>{formatAction(row.action)}</span>
            </DataTableMobileField>
            <DataTableMobileField label={t('table.resource')}>
              <ResourceCell row={row} onCopyId={onCopyId} copyIdTitle={t('table.copyId')} />
            </DataTableMobileField>
            <DataTableMobileField label={t('table.actor')}>
              <span className={styles.actor}>{row.actorEmail ?? <em>{t('table.system')}</em>}</span>
            </DataTableMobileField>
            {hasMetadata ? (
              <div className={styles.mobileMeta}>
                <button
                  type="button"
                  className={styles.detailsBtn}
                  onClick={() => onToggleExpanded(row.id)}
                  aria-expanded={isExpanded}
                >
                  {isExpanded ? t('table.hideDetails') : t('table.showDetails')}
                </button>
                {isExpanded ? <MetadataView value={row.metadata} variant="block" /> : null}
              </div>
            ) : null}
          </>
        );
      }}
    />
  );
}
