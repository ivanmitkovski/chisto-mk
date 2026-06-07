'use client';

import dynamic from 'next/dynamic';
import { useTranslations } from 'next-intl';
import { Card, ConfirmDialog, Pagination } from '@/components/ui';
import { useServerSyncedState } from '@/features/admin-shell/hooks/use-server-synced-state';
import { useWorkspaceRefresh } from '@/features/admin-shell/hooks/use-workspace-refresh';
import { WorkspaceRefreshOverlay } from '@/features/admin-shell/components/workspace-refresh-overlay';
import type { CleanupEventRow, EventsStats } from '@/features/events/data/events-adapter';
import { useEventsListUrl } from '@/features/events/hooks/use-events-list-url';
import { useEventsBulkSelection } from '@/features/events/hooks/use-events-bulk-selection';
import { useEventsBulkActions } from '@/features/events/hooks/use-events-bulk-actions';
import { EventsToolbar } from './events-toolbar';
import { EventsTable } from './events-table';
import { EventsBulkBar } from './events-bulk-bar';
import { EventsBulkModal } from './events-bulk-modal';
import styles from './events-workspace.module.css';

const EventsWorkspaceStatsMotion = dynamic(
  () =>
    import('./events-workspace-stats-motion').then((m) => ({
      default: m.EventsWorkspaceStatsMotion,
    })),
  { ssr: false, loading: () => <div className={styles.statsBar} aria-hidden /> },
);

type EventsWorkspaceProps = {
  initialData: CleanupEventRow[];
  initialMeta: { total: number; page: number; limit: number };
  initialStats: EventsStats;
  canWriteCleanupEvents: boolean;
};

export function EventsWorkspace({
  initialData,
  initialMeta,
  initialStats,
  canWriteCleanupEvents,
}: EventsWorkspaceProps) {
  const t = useTranslations('events');
  const [data] = useServerSyncedState(initialData);
  const [meta] = useServerSyncedState(initialMeta);
  const [stats] = useServerSyncedState(initialStats);

  const url = useEventsListUrl();
  const { refresh: refreshPage, isRefreshing } = useWorkspaceRefresh();
  const selection = useEventsBulkSelection(data, url.moderationStatus, canWriteCleanupEvents);
  const bulk = useEventsBulkActions({
    canWriteCleanupEvents,
    selectedIds: selection.selectedIds,
    clearSelection: selection.clearSelection,
    refresh: handleRefresh,
  });

  function handleRefresh() {
    refreshPage();
    url.refresh();
  }

  return (
    <WorkspaceRefreshOverlay isRefreshing={isRefreshing}>
    <div className={styles.layout}>
      <EventsWorkspaceStatsMotion
        stats={stats}
        totalParticipants={stats.totalParticipants}
        moderationQueueHref={url.buildUrl({ moderationStatus: 'PENDING', page: 1 })}
      />

      <Card className={styles.tableCard}>
        <EventsToolbar
          status={url.status}
          moderationStatus={url.moderationStatus}
          searchDraft={url.searchDraft}
          canWriteCleanupEvents={canWriteCleanupEvents}
          onStatusChange={url.handleStatusChange}
          onModerationChange={url.handleModerationChange}
          onSearchDraftChange={url.setSearchDraft}
          onSearch={url.applySearchToUrl}
          onRefresh={handleRefresh}
          isRefreshing={isRefreshing}
        />

        {selection.showModerationBulk ? (
          <EventsBulkBar
            selectedCount={selection.selectedIds.size}
            bulkBusy={bulk.bulkBusy}
            onSelectPage={selection.selectAllOnPage}
            onClear={selection.clearSelection}
            onApprove={() => bulk.setBulkApproveOpen(true)}
            onDecline={bulk.openBulkDeclineModal}
          />
        ) : null}

        <EventsTable
          data={data}
          showModerationBulk={selection.showModerationBulk}
          selectedIds={selection.selectedIds}
          onToggleSelected={selection.toggleRowSelected}
        />

        <div className={styles.footer}>
          <p className={styles.meta}>
            {t('table.eventsCount', { count: meta.total, page: meta.page })}
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

      <EventsBulkModal
        isOpen={bulk.bulkDeclineOpen}
        selectedCount={selection.selectedIds.size}
        reason={bulk.bulkDeclineReason}
        error={bulk.bulkDeclineError}
        busy={bulk.bulkBusy}
        onReasonChange={bulk.setBulkDeclineReason}
        onClearError={() => bulk.setBulkDeclineError(null)}
        onClose={bulk.closeBulkDeclineModal}
        onSubmit={bulk.submitBulkDecline}
      />
      <ConfirmDialog
        open={bulk.bulkApproveOpen}
        title={t('bulk.approveConfirmTitle')}
        description={t('bulk.approveConfirmDescription', { count: selection.selectedIds.size })}
        confirmLabel={t('bulk.approveSelected')}
        isLoading={bulk.bulkBusy}
        onConfirm={() => {
          bulk.setBulkApproveOpen(false);
          void bulk.bulkApprove();
        }}
        onClose={() => bulk.setBulkApproveOpen(false)}
      />
    </div>
    </WorkspaceRefreshOverlay>
  );
}
