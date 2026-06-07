'use client';

import { useState } from 'react';
import { motion } from 'framer-motion';
import { useTranslations } from 'next-intl';
import { BulkActionBar, Button, Card, Icon, Input, Pagination, useToast } from '@/components/ui';
import { WorkspaceRefreshOverlay } from '@/features/admin-shell/components/workspace-refresh-overlay';
import { useWorkspaceRefresh } from '@/features/admin-shell/hooks/use-workspace-refresh';
import { useServerSyncedState } from '@/features/admin-shell/hooks/use-server-synced-state';
import { useOptimisticMutation } from '@/features/admin-shell/hooks/use-optimistic-mutation';
import { Can, usePermissions } from '@/lib/auth/rbac';
import { adminBrowserFetch } from '@/lib/api';
import type { SiteRow, SitesStats } from '@/features/sites/data/sites-adapter';
import { SITES_STATUS_OPTIONS } from '@/features/sites/config/sites-list-filters';
import { useSitesBulkSelection } from '@/features/sites/hooks/use-sites-bulk-selection';
import { useSitesListUrl } from '@/features/sites/hooks/use-sites-list-url';
import { SitesBulkStatusModal } from './sites-bulk-status-modal';
import { SitesBulkArchiveModal } from './sites-bulk-archive-modal';
import { SitesCreateModal } from './sites-create-modal';
import { SitesTable } from './sites-table';
import styles from './sites-workspace.module.css';

type SitesWorkspaceProps = {
  initialData: SiteRow[];
  initialMeta: { total: number; page: number; limit: number };
  initialStats: SitesStats;
};

export function SitesWorkspace({
  initialData,
  initialMeta,
  initialStats,
}: SitesWorkspaceProps) {
  const t = useTranslations('sites');
  const tCommon = useTranslations('common');
  const { refresh: refreshPage, isRefreshing } = useWorkspaceRefresh();
  const url = useSitesListUrl();
  const [data] = useServerSyncedState(initialData);
  const [meta] = useServerSyncedState(initialMeta);
  const [stats] = useServerSyncedState(initialStats);
  const [bulkStatusOpen, setBulkStatusOpen] = useState(false);
  const [bulkArchiveOpen, setBulkArchiveOpen] = useState(false);
  const [createOpen, setCreateOpen] = useState(false);
  const { showToast } = useToast();
  const { can } = usePermissions();
  const canBulk = can('sites:bulk');

  const selectionKey = `${url.status}|${url.page}|${url.searchTerm}|${meta.page}`;
  const selection = useSitesBulkSelection(data, selectionKey);

  const selectedSites = data.filter((site) => selection.selectedIds.has(site.id));

  const bulkMutation = useOptimisticMutation({
    mutate: async (payload: {
      action: 'set_status' | 'set_archived';
      siteIds: string[];
      status?: string;
      archived?: boolean;
    }) => {
      return adminBrowserFetch<{ updated: number }>('/sites/admin/bulk', {
        method: 'POST',
        body: {
          siteIds: payload.siteIds,
          action: payload.action,
          ...(payload.status ? { status: payload.status } : {}),
          ...(payload.archived != null ? { archived: payload.archived } : {}),
        },
      });
    },
    onSuccess: (result) => {
      setBulkStatusOpen(false);
      setBulkArchiveOpen(false);
      selection.clearSelection();
      refreshPage();
      showToast({
        tone: 'success',
        title: t('bulk.completeTitle'),
        message: t('bulk.completeMessage', { count: result.updated }),
      });
    },
    errorToast: {
      title: t('bulk.failedTitle'),
      message: t('bulk.failedMessage'),
    },
  });

  const reportedCount = stats.byStatus['REPORTED'] ?? 0;
  const verifiedCount = stats.byStatus['VERIFIED'] ?? 0;
  const cleanedCount = stats.byStatus['CLEANED'] ?? 0;

  return (
    <WorkspaceRefreshOverlay isRefreshing={isRefreshing}>
      <div className={styles.layout}>
        <div className={styles.statsBar}>
          <motion.div
            className={styles.statCard}
            initial={{ opacity: 0, y: 4 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.2 }}
          >
            <span className={styles.statIcon}>
              <Icon name="location" size={18} aria-hidden />
            </span>
            <span className={styles.statValue}>{stats.total}</span>
            <span className={styles.statLabel}>{t('stats.totalSites')}</span>
          </motion.div>
          <motion.div
            className={styles.statCard}
            initial={{ opacity: 0, y: 4 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.2, delay: 0.05 }}
          >
            <span className={styles.statIconReported}>
              <Icon name="document-text" size={18} aria-hidden />
            </span>
            <span className={styles.statValue}>{reportedCount}</span>
            <span className={styles.statLabel}>{t('stats.reported')}</span>
          </motion.div>
          <motion.div
            className={styles.statCard}
            initial={{ opacity: 0, y: 4 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.2, delay: 0.1 }}
          >
            <span className={styles.statIconVerified}>
              <Icon name="check" size={18} aria-hidden />
            </span>
            <span className={styles.statValue}>{verifiedCount}</span>
            <span className={styles.statLabel}>{t('stats.verified')}</span>
          </motion.div>
          <motion.div
            className={styles.statCard}
            initial={{ opacity: 0, y: 4 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.2, delay: 0.15 }}
          >
            <span className={styles.statIconCleaned}>
              <Icon name="shield" size={18} aria-hidden />
            </span>
            <span className={styles.statValue}>{cleanedCount}</span>
            <span className={styles.statLabel}>{t('stats.cleaned')}</span>
          </motion.div>
        </div>

        <Card className={styles.tableCard}>
          <div className={styles.toolbar}>
            <div className={styles.filters}>
              <Input
                aria-label={t('filters.searchAria')}
                placeholder={t('filters.searchPlaceholder')}
                value={url.searchTerm}
                onChange={(event) => url.setSearchTerm(event.target.value)}
                className={styles.searchInput}
                leftSlot={<Icon name="magnifying-glass" size={14} aria-hidden />}
              />
              <select
                value={url.status}
                onChange={(e) => url.handleStatusChange(e.target.value)}
                className={styles.filterSelect}
                aria-label={t('filters.statusAria')}
              >
                {SITES_STATUS_OPTIONS.map((o) => (
                  <option key={o.value || '_'} value={o.value}>
                    {t(o.labelKey)}
                  </option>
                ))}
              </select>
            </div>
            <div className={styles.toolbarActions}>
              <Can permission="sites:write">
                <Button variant="solid" size="sm" onClick={() => setCreateOpen(true)}>
                  {t('create.createSite')}
                </Button>
              </Can>
              <Button variant="outline" size="sm" onClick={refreshPage}>
                {tCommon('refresh')}
              </Button>
            </div>
          </div>

          {canBulk ? (
            <BulkActionBar
              selectedCount={selection.selectedIds.size}
              totalCount={data.length}
              onClear={selection.clearSelection}
              actions={[
                {
                  id: 'set-status',
                  label: t('bulk.setStatus'),
                  disabled: bulkMutation.isPending,
                  onClick: () => setBulkStatusOpen(true),
                },
                {
                  id: 'set-archived',
                  label: t('bulk.archiveVisibility'),
                  disabled: bulkMutation.isPending,
                  onClick: () => setBulkArchiveOpen(true),
                },
              ]}
            />
          ) : null}

          <SitesTable
            data={data}
            canBulk={canBulk}
            selectedIds={selection.selectedIds}
            allSelected={selection.allSelected}
            selectAllRef={selection.selectAllRef}
            onToggleAll={selection.toggleAll}
            onToggleSelection={selection.toggleSelection}
          />

          <div className={styles.footer}>
            <p className={styles.meta}>
              {t('table.sitesMeta', { count: meta.total, page: meta.page })}
            </p>
            {meta.total > meta.limit && (
              <Pagination
                totalPages={Math.ceil(meta.total / meta.limit)}
                currentPage={meta.page}
                onPageChange={(p) => url.router.push(url.buildUrl({ page: p }))}
              />
            )}
          </div>
        </Card>

        <SitesCreateModal open={createOpen} onClose={() => setCreateOpen(false)} onCreated={refreshPage} />
        <SitesBulkStatusModal
          open={bulkStatusOpen}
          selectedSites={selectedSites}
          busy={bulkMutation.isPending}
          onClose={() => !bulkMutation.isPending && setBulkStatusOpen(false)}
          onConfirm={(targetStatus, validSiteIds) =>
            void bulkMutation.run({ action: 'set_status', status: targetStatus, siteIds: validSiteIds })
          }
        />
        <SitesBulkArchiveModal
          open={bulkArchiveOpen}
          selectedCount={selection.selectedIds.size}
          busy={bulkMutation.isPending}
          onClose={() => !bulkMutation.isPending && setBulkArchiveOpen(false)}
          onConfirm={(archived) =>
            void bulkMutation.run({
              action: 'set_archived',
              archived,
              siteIds: Array.from(selection.selectedIds),
            })
          }
        />
      </div>
    </WorkspaceRefreshOverlay>
  );
}
