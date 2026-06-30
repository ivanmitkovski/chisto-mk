'use client';

import { useCallback, useState } from 'react';
import Link from 'next/link';
import { AnimatePresence, motion, useReducedMotion } from 'framer-motion';
import { useRouter } from 'next/navigation';
import { useTranslations } from 'next-intl';
import { BROADCAST_PREFILL_STORAGE_KEY } from '@/features/broadcasts/types';
import { WorkspaceRefreshOverlay } from '@/features/admin-shell/components/workspace-refresh-overlay';
import { useWorkspaceRefresh } from '@/features/admin-shell/hooks/use-workspace-refresh';
import { useServerSyncedState } from '@/features/admin-shell/hooks/use-server-synced-state';
import { usePermissions } from '@/lib/auth/rbac';
import type { UserRow, UsersStats } from '@/features/users/data/users-adapter';
import { ActionConfirmModal } from '@/features/reports/components/action-confirm-modal';
import { Card, Icon, PageHeader, Pagination, useToast } from '@/components/ui';
import { adminBrowserFetch } from '@/lib/api';
import { useUsersListHighlight } from '@/features/users/hooks/use-users-list-highlight';
import { buildUsersExportCsv } from '@/features/users/lib/build-users-export-csv';
import { UserSuspendReasonModal } from './user-suspend-reason-modal';
import { useUsersListUrl } from '@/features/users/hooks/use-users-list-url';
import { useUsersBulkSelection } from '@/features/users/hooks/use-users-bulk-selection';
import { useUsersBulkActions } from '@/features/users/hooks/use-users-bulk-actions';
import { UsersToolbar } from './users-toolbar';
import { UsersBulkBar } from './users-bulk-bar';
import { UsersBulkRoleModal } from './users-bulk-role-modal';
import { UsersTable } from './users-table';
import styles from './users-workspace.module.css';

type UsersWorkspaceProps = {
  initialData: UserRow[];
  initialMeta: { total: number; page: number; limit: number };
  initialStats: UsersStats;
};

function sevenDaysAgoIso(): string {
  const date = new Date();
  date.setDate(date.getDate() - 7);
  return date.toISOString().slice(0, 10);
}

export function UsersWorkspace({ initialData, initialMeta, initialStats }: UsersWorkspaceProps) {
  const t = useTranslations('users');
  const tCommon = useTranslations('common');
  const { showToast } = useToast();
  const router = useRouter();
  const reduceMotion = useReducedMotion();
  const { refresh: refreshPage, isRefreshing } = useWorkspaceRefresh();
  const [data] = useServerSyncedState(initialData);
  const [meta] = useServerSyncedState(initialMeta);
  const [stats] = useServerSyncedState(initialStats);
  const { can } = usePermissions();
  const canBulkWrite = can('users:write');
  const canBulkRole = can('users:role:write');
  const canBroadcast = can('notifications:broadcast');
  const showBulkUi = canBulkWrite || canBulkRole || canBroadcast;

  const url = useUsersListUrl();
  const selectionKey = `${url.role}|${url.status}|${url.page}|${url.searchTerm}|${url.sort}|${url.dir}|${url.lastActiveBefore}|${url.lastActiveAfter}|${url.createdAfter}`;
  const selection = useUsersBulkSelection(data, selectionKey);
  const bulk = useUsersBulkActions(refreshPage);
  const { highlightedUserIds } = useUsersListHighlight();
  const [bulkSuspendReasonOpen, setBulkSuspendReasonOpen] = useState(false);
  const [exporting, setExporting] = useState(false);

  async function handleBulkConfirm() {
    if (!bulk.bulkModal) return;
    if (bulk.bulkModal === 'suspend') {
      bulk.setBulkModal(null);
      setBulkSuspendReasonOpen(true);
      return;
    }
    const ok = await bulk.runBulkAction(bulk.bulkModal, selection.selectedIds);
    if (ok) selection.clearSelection();
  }

  async function handleBulkSuspendWithReason(reasonCode: string, note: string) {
    const ok = await bulk.runBulkAction('suspend', selection.selectedIds, { reasonCode, note });
    setBulkSuspendReasonOpen(false);
    if (ok) selection.clearSelection();
  }

  async function handleBulkRoleConfirm(role: string) {
    const ok = await bulk.runBulkAction('changeRole', selection.selectedIds, { role });
    if (ok) selection.clearSelection();
  }

  const exportCsv = useCallback(async () => {
    setExporting(true);
    try {
      const sp = new URLSearchParams({ page: '1', limit: '500' });
      if (url.searchTerm) sp.set('search', url.searchTerm);
      if (url.role) sp.set('role', url.role);
      if (url.status) sp.set('status', url.status);
      if (url.sort) sp.set('sort', url.sort);
      if (url.dir) sp.set('dir', url.dir);
      if (url.lastActiveBefore) sp.set('lastActiveBefore', url.lastActiveBefore);
      if (url.lastActiveAfter) sp.set('lastActiveAfter', url.lastActiveAfter);
      if (url.createdAfter) sp.set('createdAfter', url.createdAfter);

      const result = await adminBrowserFetch<{ data: UserRow[] }>(`/admin/users?${sp.toString()}`);
      const csv = buildUsersExportCsv(result.data);
      const blob = new Blob([csv], { type: 'text/csv;charset=utf-8' });
      const blobUrl = URL.createObjectURL(blob);
      const anchor = document.createElement('a');
      anchor.href = blobUrl;
      anchor.download = `users-export-${new Date().toISOString().slice(0, 10)}.csv`;
      anchor.click();
      URL.revokeObjectURL(blobUrl);
      showToast({
        tone: 'success',
        title: tCommon('exportReady'),
        message: tCommon('exportedRows', { count: result.data.length }),
      });
    } catch (error) {
      showToast({
        tone: 'warning',
        title: tCommon('exportFailed'),
        message: error instanceof Error ? error.message : tCommon('exportFailed'),
      });
    } finally {
      setExporting(false);
    }
  }, [
    showToast,
    tCommon,
    url.createdAfter,
    url.dir,
    url.lastActiveAfter,
    url.lastActiveBefore,
    url.role,
    url.searchTerm,
    url.sort,
    url.status,
  ]);

  function handleSendBroadcast() {
    const ids = Array.from(selection.selectedIds);
    if (ids.length === 0) return;

    if (ids.length <= 20) {
      router.push(
        `/dashboard/broadcasts?audience=users&userIds=${encodeURIComponent(ids.join(','))}`,
      );
    } else {
      sessionStorage.setItem(BROADCAST_PREFILL_STORAGE_KEY, JSON.stringify(ids));
      router.push('/dashboard/broadcasts?audience=users&prefill=storage');
    }
    selection.clearSelection();
  }

  const newUsersHref = url.buildUrl({
    createdAfter: sevenDaysAgoIso(),
    sort: 'createdAt',
    dir: 'desc',
    page: 1,
    status: '',
    role: '',
    search: '',
    lastActiveBefore: '',
    lastActiveAfter: '',
  });

  return (
    <WorkspaceRefreshOverlay isRefreshing={isRefreshing}>
      <div className={styles.layout}>
        <a href="#users-table" className="skipLink">
          {tCommon('skipToUsersTable')}
        </a>

        <PageHeader title={t('pageTitle')} description={t('pageDescription')} />

        <div className={styles.statsBar}>
          <motion.div
            className={styles.statCard}
            initial={reduceMotion ? false : { opacity: 0, y: 4 }}
            animate={{ opacity: 1, y: 0 }}
            transition={reduceMotion ? { duration: 0 } : { duration: 0.2 }}
          >
            <Link href="/dashboard/users" className={styles.statCardLink}>
              <span className={styles.statIcon}>
                <Icon name="users" size={18} aria-hidden />
              </span>
              <span className={styles.statValue}>{stats.usersCount}</span>
              <span className={styles.statLabel}>{t('stats.totalUsers')}</span>
            </Link>
          </motion.div>
          <motion.div
            className={styles.statCard}
            initial={reduceMotion ? false : { opacity: 0, y: 4 }}
            animate={{ opacity: 1, y: 0 }}
            transition={reduceMotion ? { duration: 0 } : { duration: 0.2, delay: 0.05 }}
          >
            <Link href={newUsersHref} className={styles.statCardLink}>
              <span className={styles.statIcon}>
                <Icon name="document-forward" size={18} aria-hidden />
              </span>
              <span className={styles.statValue}>{stats.usersNewLast7d}</span>
              <span className={styles.statLabel}>{t('stats.new7d')}</span>
            </Link>
          </motion.div>
          <motion.div
            className={styles.statCard}
            initial={reduceMotion ? false : { opacity: 0, y: 4 }}
            animate={{ opacity: 1, y: 0 }}
            transition={reduceMotion ? { duration: 0 } : { duration: 0.2, delay: 0.1 }}
          >
            <Link href={url.buildUrl({ status: 'SUSPENDED', page: 1 })} className={styles.statCardLink}>
              <span className={styles.statIcon}>
                <Icon name="alert-triangle" size={18} aria-hidden />
              </span>
              <span className={styles.statValue}>{stats.usersSuspendedCount}</span>
              <span className={styles.statLabel}>{t('stats.suspended')}</span>
            </Link>
          </motion.div>
          <motion.div
            className={styles.statCard}
            initial={reduceMotion ? false : { opacity: 0, y: 4 }}
            animate={{ opacity: 1, y: 0 }}
            transition={reduceMotion ? { duration: 0 } : { duration: 0.2, delay: 0.15 }}
          >
            <Link href="/dashboard/active-users" className={styles.statCardLink}>
              <span className={styles.statIcon}>
                <Icon name="shield" size={18} aria-hidden />
              </span>
              <span className={styles.statValue}>{stats.sessionsActive}</span>
              <span className={styles.statLabel}>{t('stats.activeSessions')}</span>
            </Link>
          </motion.div>
        </div>

        <Card className={styles.tableCard} id="users-table">
          <UsersToolbar
            searchTerm={url.searchTerm}
            role={url.role}
            status={url.status}
            quickFilter={url.quickFilter}
            draftLastActiveBefore={url.draftLastActiveBefore}
            draftLastActiveAfter={url.draftLastActiveAfter}
            isRefreshing={isRefreshing}
            onSearchTermChange={url.setSearchTerm}
            onRoleChange={url.handleRoleChange}
            onStatusChange={url.handleStatusChange}
            onQuickFilter={url.handleQuickFilter}
            onDraftLastActiveBeforeChange={url.setDraftLastActiveBefore}
            onDraftLastActiveAfterChange={url.setDraftLastActiveAfter}
            onApplyLastActiveFilters={url.applyLastActiveFilters}
            onClearLastActiveFilters={url.clearLastActiveFilters}
            onRefresh={refreshPage}
            onExportCsv={() => void exportCsv()}
            exporting={exporting}
          />

          <AnimatePresence>
            {showBulkUi && selection.someSelected ? (
              <UsersBulkBar
                selectedCount={selection.selectedIds.size}
                isBulkLoading={bulk.isBulkLoading}
                canBulkWrite={canBulkWrite}
                canBulkRole={canBulkRole}
                canBroadcast={canBroadcast}
                onActivate={() => bulk.setBulkModal('activate')}
                onSuspend={() => bulk.setBulkModal('suspend')}
                onChangeRole={() => bulk.setRoleModalOpen(true)}
                onSendBroadcast={handleSendBroadcast}
                onClear={selection.clearSelection}
              />
            ) : null}
          </AnimatePresence>

          <UsersTable
            data={data}
            canBulk={showBulkUi}
            highlightedUserIds={highlightedUserIds}
            selectedIds={selection.selectedIds}
            allSelected={selection.allSelected}
            selectAllRef={selection.selectAllRef}
            onToggleAll={selection.toggleAll}
            onToggleSelection={selection.toggleSelection}
            sortKey={url.sort}
            sortDir={url.dir}
            onSort={url.handleSort}
          />

          <div className={styles.footer}>
            <p className={styles.meta}>
              {t('table.usersCount', { count: meta.total, page: meta.page })}
            </p>
            {meta.total > meta.limit ? (
              <Pagination
                totalPages={Math.ceil(meta.total / meta.limit)}
                currentPage={meta.page}
                onPageChange={(p) => url.router.push(url.buildUrl({ page: p }))}
              />
            ) : null}
          </div>
        </Card>
      </div>

      <UsersBulkRoleModal
        open={bulk.roleModalOpen}
        selectedCount={selection.selectedIds.size}
        busy={bulk.isBulkLoading}
        onClose={() => !bulk.isBulkLoading && bulk.setRoleModalOpen(false)}
        onConfirm={(role) => void handleBulkRoleConfirm(role)}
      />

      <ActionConfirmModal
        isOpen={bulk.bulkModal !== null}
        title={bulk.bulkModal === 'suspend' ? t('bulk.suspendTitle') : t('bulk.activateTitle')}
        description={
          bulk.bulkModal === 'suspend'
            ? t('bulk.suspendDescription', { count: selection.selectedIds.size })
            : t('bulk.activateDescription', { count: selection.selectedIds.size })
        }
        confirmLabel={bulk.bulkModal === 'suspend' ? t('bulk.suspend') : t('bulk.activate')}
        confirmTone={bulk.bulkModal === 'suspend' ? 'danger' : 'default'}
        isConfirming={bulk.isBulkLoading}
        onCancel={() => !bulk.isBulkLoading && bulk.setBulkModal(null)}
        onConfirm={() => void handleBulkConfirm()}
      />

      <UserSuspendReasonModal
        open={bulkSuspendReasonOpen}
        busy={bulk.isBulkLoading}
        onClose={() => !bulk.isBulkLoading && setBulkSuspendReasonOpen(false)}
        onConfirm={(payload) => void handleBulkSuspendWithReason(payload.reasonCode, payload.note ?? '')}
      />
    </WorkspaceRefreshOverlay>
  );
}
