'use client';

import { AnimatePresence, motion } from 'framer-motion';
import { useTranslations } from 'next-intl';
import { WorkspaceRefreshOverlay } from '@/features/admin-shell/components/workspace-refresh-overlay';
import { useWorkspaceRefresh } from '@/features/admin-shell/hooks/use-workspace-refresh';
import { useServerSyncedState } from '@/features/admin-shell/hooks/use-server-synced-state';
import { usePermissions } from '@/lib/auth/rbac';
import type { UserRow, UsersStats } from '@/features/users/data/users-adapter';
import { ActionConfirmModal } from '@/features/reports/components/action-confirm-modal';
import { Card, Icon, Pagination } from '@/components/ui';
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

export function UsersWorkspace({ initialData, initialMeta, initialStats }: UsersWorkspaceProps) {
  const t = useTranslations('users');
  const tCommon = useTranslations('common');
  const { refresh: refreshPage, isRefreshing } = useWorkspaceRefresh();
  const [data] = useServerSyncedState(initialData);
  const [meta] = useServerSyncedState(initialMeta);
  const [stats] = useServerSyncedState(initialStats);
  const { can } = usePermissions();
  const canBulkWrite = can('users:write');
  const canBulkRole = can('users:role:write');
  const showBulkUi = canBulkWrite || canBulkRole;

  const url = useUsersListUrl();
  const selectionKey = `${url.role}|${url.status}|${url.page}|${url.searchTerm}|${url.sort}|${url.dir}`;
  const selection = useUsersBulkSelection(data, selectionKey);
  const bulk = useUsersBulkActions(refreshPage);

  async function handleBulkConfirm() {
    if (!bulk.bulkModal) return;
    const ok = await bulk.runBulkAction(bulk.bulkModal, selection.selectedIds);
    if (ok) selection.clearSelection();
  }

  async function handleBulkRoleConfirm(role: string) {
    const ok = await bulk.runBulkAction('changeRole', selection.selectedIds, role);
    if (ok) selection.clearSelection();
  }

  return (
    <WorkspaceRefreshOverlay isRefreshing={isRefreshing}>
      <div className={styles.layout}>
        <a href="#users-table" className="skipLink">
          {tCommon('skipToUsersTable')}
        </a>
        <div className={styles.statsBar}>
          <motion.div
            className={styles.statCard}
            initial={{ opacity: 0, y: 4 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.2 }}
          >
            <span className={styles.statIcon}>
              <Icon name="users" size={18} aria-hidden />
            </span>
            <span className={styles.statValue}>{stats.usersCount}</span>
            <span className={styles.statLabel}>{t('stats.totalUsers')}</span>
          </motion.div>
          <motion.div
            className={styles.statCard}
            initial={{ opacity: 0, y: 4 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.2, delay: 0.05 }}
          >
            <span className={styles.statIcon}>
              <Icon name="document-forward" size={18} aria-hidden />
            </span>
            <span className={styles.statValue}>{stats.usersNewLast7d}</span>
            <span className={styles.statLabel}>{t('stats.new7d')}</span>
          </motion.div>
          <motion.div
            className={styles.statCard}
            initial={{ opacity: 0, y: 4 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.2, delay: 0.1 }}
          >
            <span className={styles.statIcon}>
              <Icon name="shield" size={18} aria-hidden />
            </span>
            <span className={styles.statValue}>{stats.sessionsActive}</span>
            <span className={styles.statLabel}>{t('stats.activeSessions')}</span>
          </motion.div>
        </div>

        <Card className={styles.tableCard} id="users-table">
          <UsersToolbar
            searchTerm={url.searchTerm}
            role={url.role}
            status={url.status}
            onSearchTermChange={url.setSearchTerm}
            onRoleChange={url.handleRoleChange}
            onStatusChange={url.handleStatusChange}
            onRefresh={refreshPage}
          />

          <AnimatePresence>
            {showBulkUi && selection.someSelected ? (
              <UsersBulkBar
                selectedCount={selection.selectedIds.size}
                isBulkLoading={bulk.isBulkLoading}
                canBulkWrite={canBulkWrite}
                canBulkRole={canBulkRole}
                onActivate={() => bulk.setBulkModal('activate')}
                onSuspend={() => bulk.setBulkModal('suspend')}
                onChangeRole={() => bulk.setRoleModalOpen(true)}
                onClear={selection.clearSelection}
              />
            ) : null}
          </AnimatePresence>

          <UsersTable
            data={data}
            canBulk={showBulkUi}
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
    </WorkspaceRefreshOverlay>
  );
}
