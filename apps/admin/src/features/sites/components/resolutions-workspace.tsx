'use client';

import { useMemo, useState } from 'react';
import Link from 'next/link';
import { useRouter, useSearchParams } from 'next/navigation';
import { useTranslations } from 'next-intl';
import { Button, Card, DataTable, Pagination, Select, type DataTableColumn } from '@/components/ui';
import { useServerSyncedState } from '@/features/admin-shell/hooks/use-server-synced-state';
import type { SiteResolutionRow, SiteResolutionStatus } from '../data/resolutions-adapter';
import { patchSiteResolutionStatus } from '../lib/patch-site-resolution-status';
import styles from './resolutions-workspace.module.css';

type ResolutionsWorkspaceProps = {
  initialData: SiteResolutionRow[];
  initialMeta: { page: number; limit: number; total: number };
};

const STATUS_OPTIONS: Array<{ value: '' | SiteResolutionStatus; labelKey: string }> = [
  { value: '', labelKey: 'filters.all' },
  { value: 'PENDING', labelKey: 'filters.pending' },
  { value: 'APPROVED', labelKey: 'filters.approved' },
  { value: 'REJECTED', labelKey: 'filters.rejected' },
];

export function ResolutionsWorkspace({ initialData, initialMeta }: ResolutionsWorkspaceProps) {
  const t = useTranslations('resolutions');
  const router = useRouter();
  const searchParams = useSearchParams();
  const [data] = useServerSyncedState(initialData);
  const [meta] = useServerSyncedState(initialMeta);
  const [busyId, setBusyId] = useState<string | null>(null);

  const statusFilter = (searchParams.get('status') ?? '') as '' | SiteResolutionStatus;

  const columns = useMemo<DataTableColumn<SiteResolutionRow>[]>(
    () => [
      {
        key: 'createdAt',
        header: t('table.submitted'),
        render: (row) => new Date(row.createdAt).toLocaleString(),
      },
      {
        key: 'site',
        header: t('table.site'),
        render: (row) => (
          <Link href={`/dashboard/sites/${row.siteId}`} className={styles.siteLink}>
            {row.siteAddress?.trim() || row.siteId}
          </Link>
        ),
      },
      {
        key: 'submitter',
        header: t('table.submitter'),
        render: (row) => row.submitterDisplayLabel ?? '—',
      },
      {
        key: 'status',
        header: t('table.status'),
        render: (row) => row.status.replace(/_/g, ' '),
      },
      {
        key: 'photos',
        header: t('table.photos'),
        render: (row) => row.mediaUrls.length,
      },
      {
        key: 'actions',
        header: t('table.actions'),
        render: (row) =>
          row.status === 'PENDING' ? (
            <div className={styles.rowActions}>
              <Button
                size="sm"
                disabled={busyId === row.id}
                isLoading={busyId === row.id}
                onClick={async () => {
                  setBusyId(row.id);
                  await patchSiteResolutionStatus(row.id, 'APPROVED');
                  setBusyId(null);
                  router.refresh();
                }}
              >
                {t('approve')}
              </Button>
            </div>
          ) : (
            '—'
          ),
      },
    ],
    [busyId, router, t],
  );

  function setStatusFilter(next: '' | SiteResolutionStatus) {
    const params = new URLSearchParams(searchParams.toString());
    if (next) params.set('status', next);
    else params.delete('status');
    params.set('page', '1');
    router.push(`/dashboard/resolutions?${params.toString()}`);
  }

  function handlePageChange(page: number) {
    const params = new URLSearchParams(searchParams.toString());
    params.set('page', String(page));
    router.push(`/dashboard/resolutions?${params.toString()}`);
  }

  return (
    <div className={styles.layout}>
      <Card className={styles.tableCard}>
        <div className={styles.toolbar}>
          <div className={styles.statusFilter}>
            <Select
              label={t('filters.status')}
              value={statusFilter}
              options={STATUS_OPTIONS.map((opt) => ({
                value: opt.value,
                label: t(opt.labelKey),
              }))}
              onChange={(e) => setStatusFilter(e.target.value as '' | SiteResolutionStatus)}
            />
          </div>
        </div>

        <DataTable columns={columns} data={data} getRowId={(row) => row.id} emptyMessage={t('table.empty')} />

        <div className={styles.footer}>
          <p className={styles.meta}>
            {t('table.resolutionsCount', { count: meta.total, page: meta.page })}
          </p>
          {meta.total > meta.limit ? (
            <div className={styles.footerNav}>
              <Pagination
                totalPages={Math.ceil(meta.total / meta.limit)}
                currentPage={meta.page}
                onPageChange={handlePageChange}
              />
            </div>
          ) : null}
        </div>
      </Card>
    </div>
  );
}
