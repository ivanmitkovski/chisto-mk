'use client';

import type { RefObject } from 'react';
import Link from 'next/link';
import { useTranslations } from 'next-intl';
import {
  Checkbox,
  DataTable,
  DataTableLink,
  DataTableMobileField,
  type DataTableColumn,
} from '@/components/ui';
import type { SiteRow } from '@/features/sites/data/sites-adapter';
import styles from './sites-workspace.module.css';

function statusPillClass(status: string): string {
  const map: Record<string, string> = {
    REPORTED: styles.statusReported,
    VERIFIED: styles.statusVerified,
    CLEANUP_SCHEDULED: styles.statusScheduled,
    IN_PROGRESS: styles.statusInProgress,
    CLEANED: styles.statusCleaned,
    DISPUTED: styles.statusDisputed,
  };
  return `${styles.statusPill} ${map[status] ?? styles.statusDefault}`;
}

function formatStatus(status: string): string {
  return status.replace(/_/g, ' ').toLowerCase().replace(/\b\w/g, (c) => c.toUpperCase());
}

const STATUS_LABEL_KEY_BY_VALUE: Record<string, string> = {
  REPORTED: 'filters.reported',
  VERIFIED: 'filters.verified',
  CLEANUP_SCHEDULED: 'filters.cleanupScheduled',
  IN_PROGRESS: 'filters.inProgress',
  CLEANED: 'filters.cleaned',
  DISPUTED: 'filters.disputed',
};

function translateStatus(status: string, t: (key: string) => string): string {
  const key = STATUS_LABEL_KEY_BY_VALUE[status];
  return key ? t(key) : formatStatus(status);
}

function mapLinks(lat: number, lng: number) {
  const gm = `https://www.google.com/maps?q=${lat},${lng}`;
  const am = `https://maps.apple.com/?q=${lat},${lng}`;
  return { gm, am };
}

function LocationCell({
  site,
  openInGoogleMapsLabel,
  openInAppleMapsLabel,
}: {
  site: SiteRow;
  openInGoogleMapsLabel: string;
  openInAppleMapsLabel: string;
}) {
  const { gm, am } = mapLinks(site.latitude, site.longitude);
  return (
    <div className={styles.locationCell}>
      <Link href={`/dashboard/sites/${site.id}`} className={styles.coordsLink}>
        {site.latitude.toFixed(5)}, {site.longitude.toFixed(5)}
      </Link>
      <div className={styles.mapLinks}>
        <a
          href={gm}
          target="_blank"
          rel="noopener noreferrer"
          className={styles.mapLink}
          aria-label={openInGoogleMapsLabel}
        >
          {openInGoogleMapsLabel}
        </a>
        <span className={styles.mapDivider}>·</span>
        <a
          href={am}
          target="_blank"
          rel="noopener noreferrer"
          className={styles.mapLink}
          aria-label={openInAppleMapsLabel}
        >
          {openInAppleMapsLabel}
        </a>
      </div>
      {site.description ? <p className={styles.description}>{site.description}</p> : null}
    </div>
  );
}

type SitesTableProps = {
  data: SiteRow[];
  canBulk: boolean;
  selectedIds: Set<string>;
  allSelected: boolean;
  selectAllRef: RefObject<HTMLInputElement | null>;
  onToggleAll: () => void;
  onToggleSelection: (id: string) => void;
};

export function SitesTable({
  data,
  canBulk,
  selectedIds,
  allSelected,
  selectAllRef,
  onToggleAll,
  onToggleSelection,
}: SitesTableProps) {
  const t = useTranslations('sites');
  const tCommon = useTranslations('common');

  const bulkColumn: DataTableColumn<SiteRow> = {
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
    render: (s) => (
      <Checkbox
        checked={selectedIds.has(s.id)}
        onChange={() => onToggleSelection(s.id)}
        aria-label={t('table.selectSiteAria', { id: s.id })}
      />
    ),
  };

  const columns: DataTableColumn<SiteRow>[] = [
    ...(canBulk ? [bulkColumn] : []),
    {
      key: 'location',
      header: t('table.location'),
      render: (s) => (
        <LocationCell
          site={s}
          openInGoogleMapsLabel={tCommon('openInGoogleMaps')}
          openInAppleMapsLabel={tCommon('openInAppleMaps')}
        />
      ),
    },
    {
      key: 'status',
      header: t('table.status'),
      render: (s) => (
        <span className={statusPillClass(s.status)}>{translateStatus(s.status, t)}</span>
      ),
    },
    {
      key: 'reports',
      header: t('table.reports'),
      render: (s) =>
        s.reportCount > 0 ? (
          <Link href={`/dashboard/reports?siteId=${s.id}`} className={styles.reportsLink}>
            {s.reportCount}
          </Link>
        ) : (
          <span className={styles.reportsCount}>{s.reportCount}</span>
        ),
    },
    {
      key: 'actions',
      header: t('table.actions'),
      render: (s) => (
        <DataTableLink href={`/dashboard/sites/${s.id}`}>{t('table.view')}</DataTableLink>
      ),
    },
  ];

  return (
    <DataTable
      columns={columns}
      data={data}
      getRowId={(s) => s.id}
      caption={t('table.caption')}
      emptyMessage={t('table.empty')}
      tableClassName={canBulk ? `${styles.table} ${styles.tableWithBulk}` : styles.table}
      getRowClassName={(s) => (selectedIds.has(s.id) ? styles.rowSelected : undefined)}
      getRowAriaCurrent={(s) => selectedIds.has(s.id)}
      getMobileCardClassName={(s) =>
        selectedIds.has(s.id) ? styles.mobileCardSelected : undefined
      }
      renderMobileCard={(s) => (
        <>
          {canBulk ? (
            <div className={styles.mobileCardHeader}>
              <Checkbox
                checked={selectedIds.has(s.id)}
                onChange={() => onToggleSelection(s.id)}
                aria-label={t('table.selectSiteAria', { id: s.id })}
              />
              <LocationCell
                site={s}
                openInGoogleMapsLabel={tCommon('openInGoogleMaps')}
                openInAppleMapsLabel={tCommon('openInAppleMaps')}
              />
            </div>
          ) : (
            <LocationCell
              site={s}
              openInGoogleMapsLabel={tCommon('openInGoogleMaps')}
              openInAppleMapsLabel={tCommon('openInAppleMaps')}
            />
          )}
          <DataTableMobileField label={t('table.status')}>
            <span className={statusPillClass(s.status)}>{translateStatus(s.status, t)}</span>
          </DataTableMobileField>
          <DataTableMobileField label={t('table.reports')}>
            {s.reportCount > 0 ? (
              <Link href={`/dashboard/reports?siteId=${s.id}`} className={styles.reportsLink}>
                {s.reportCount}
              </Link>
            ) : (
              <span className={styles.reportsCount}>{s.reportCount}</span>
            )}
          </DataTableMobileField>
          <div className={styles.mobileCardActions}>
            <DataTableLink href={`/dashboard/sites/${s.id}`}>{t('table.viewSite')}</DataTableLink>
          </div>
        </>
      )}
    />
  );
}
