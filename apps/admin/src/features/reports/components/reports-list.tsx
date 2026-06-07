'use client';

import { Suspense, useCallback, useMemo, useRef, useState } from 'react';
import { useTranslations } from 'next-intl';
import { useRouter } from 'next/navigation';
import { motion, useReducedMotion } from 'framer-motion';
import { Card, Pagination } from '@/components/ui';
import { useServerSyncedState } from '@/features/admin-shell';
import type { ReportRow } from '@/features/reports/types';
import { buildReportsUrl, REPORTS_LIST_OVERVIEW_MAX_ROWS } from './reports-list-utils';
import { getStatusFilterOptions } from '@/features/reports/config/table';
import { useReportsListQuery } from '@/features/reports/hooks/use-reports-list-query';
import { useReportsListHighlight } from '@/features/reports/hooks/use-reports-list-highlight';
import { useReportsListConfirm } from '@/features/reports/hooks/use-reports-list-confirm';
import { useRejectionReasonOptions } from '@/features/reports/hooks/use-rejection-reason-options';
import { ReportsListEmptyState } from './reports-list/reports-list-empty-state';
import { ReportsListQueueHeader } from './reports-list/reports-list-queue-header';
import { ReportsListSkeleton } from './reports-list/reports-list-skeleton';
import { ReportsListToolbar } from './reports-list/reports-list-toolbar';
import { ReportsListTable } from './reports-list/reports-list-table';
import { ReportsListMobileList } from './reports-list/reports-list-mobile-list';
import { ActionConfirmModal } from './action-confirm-modal';
import styles from './reports-list.module.css';

const REFRESH_DEBOUNCE_MS = 800;
const SPRING = { type: 'spring' as const, stiffness: 400, damping: 30 };

type ReportsListProps = {
  reports: ReportRow[];
  variant?: 'overview' | 'full';
  embedded?: boolean;
  maxRows?: number;
  prioritizePending?: boolean;
  serverMeta?: { page: number; limit: number; total: number };
  initialSearch?: string;
  siteIdFilter?: string;
  queueSummary?: import('../data/reports-adapter').ReportsQueueSummary;
};

function ReportsListInner({
  reports: initialReports,
  variant = 'full',
  embedded = false,
  maxRows = REPORTS_LIST_OVERVIEW_MAX_ROWS,
  prioritizePending = false,
  serverMeta,
  initialSearch = '',
  siteIdFilter,
  queueSummary,
}: ReportsListProps) {
  const router = useRouter();
  const t = useTranslations('reports');
  const tCommon = useTranslations('common');
  const tConfirm = useTranslations('reports.confirm');
  const tRejection = useTranslations('reports.rejectionReasons');
  const reducedMotion = useReducedMotion();
  const [isRefreshing, setIsRefreshing] = useState(false);
  const lastRefreshRef = useRef(0);
  const [reports, setReports] = useServerSyncedState(initialReports);
  const statusFilters = useMemo(() => getStatusFilterOptions(t), [t]);
  const rejectionReasonOptions = useRejectionReasonOptions();

  const query = useReportsListQuery({
    reports,
    variant,
    maxRows,
    prioritizePending,
    initialSearch,
    ...(serverMeta ? { serverMeta } : {}),
    ...(siteIdFilter ? { siteIdFilter } : {}),
    ...(queueSummary ? { queueSummary } : {}),
  });
  const { highlightedReportIds } = useReportsListHighlight(reports);
  const confirm = useReportsListConfirm({
    onOptimisticStatus: (id, status) => {
      setReports((current) => current.map((row) => (row.id === id ? { ...row, status } : row)));
    },
    onRollbackStatus: (id, status) => {
      setReports((current) => current.map((row) => (row.id === id ? { ...row, status } : row)));
    },
  });

  const handleRefresh = useCallback(() => {
    const now = Date.now();
    if (now - lastRefreshRef.current < REFRESH_DEBOUNCE_MS) return;
    lastRefreshRef.current = now;
    setIsRefreshing(true);
    router.refresh();
    window.setTimeout(() => setIsRefreshing(false), REFRESH_DEBOUNCE_MS);
  }, [router]);

  function pageHref(page: number): string {
    if (query.isOverview) return '#';
    return buildReportsUrl({
      status: query.activeFilter !== 'ALL' && query.activeFilter !== 'DUPLICATES' ? query.activeFilter : undefined,
      sort: query.sortKey,
      dir: query.sortDirection,
      page: page > 1 ? page : undefined,
      search: query.debouncedSearch.trim() || undefined,
      siteId: query.siteIdFilter,
      duplicatesOnly: query.duplicatesOnly ? true : undefined,
    });
  }

  return (
    <motion.section
      id={embedded ? undefined : 'reports-section'}
      className={styles.section}
      aria-labelledby={embedded ? undefined : 'reports-heading'}
      initial={reducedMotion ? false : { opacity: 0, y: 8 }}
      animate={{ opacity: 1, y: 0 }}
      transition={reducedMotion ? { duration: 0 } : SPRING}
    >
      {!embedded && (
        <ReportsListQueueHeader
          reportsCount={query.isServerPaginated ? query.totalItems : reports.length}
          needAttentionCount={query.needAttentionCount}
          duplicateCount={query.duplicateCount}
          isRefreshing={isRefreshing}
          onRefresh={handleRefresh}
          sublineText={query.sublineText}
        />
      )}
      <ReportsListToolbar
        isOverview={query.isOverview}
        searchTerm={query.searchTerm}
        onSearchTermChange={query.setSearchTerm}
        onClearSearch={() => query.setSearchTerm('')}
        statusFilters={statusFilters}
        activeFilter={query.activeFilter}
        onOverviewFilterSelect={query.setLocalStatusFilter}
        filterHref={query.filterHref}
      />
      <Card as="div" padding="sm" className={styles.tableCard}>
        {query.sortedReports.length === 0 ? (
          <ReportsListEmptyState
            totalReportsCount={query.isServerPaginated ? query.totalItems : reports.length}
            filteredByStatusCount={query.filteredByStatus.length}
            debouncedSearch={query.debouncedSearch}
          />
        ) : (
          <>
            <ReportsListTable
              reports={query.paginatedReports}
              highlightedReportIds={highlightedReportIds}
              isOverview={query.isOverview}
              reducedMotion={!!reducedMotion}
              onSort={query.handleSort}
              sortIconName={query.sortIconName}
              ariaSortValue={query.ariaSortValue}
              sortHref={query.sortHref}
              onApprove={confirm.openApproveModal}
              onReject={confirm.openRejectModal}
            />
            <ReportsListMobileList
              reports={query.paginatedReports}
              highlightedReportIds={highlightedReportIds}
              reducedMotion={!!reducedMotion}
              onApprove={confirm.openApproveModal}
              onReject={confirm.openRejectModal}
            />
            {!query.isOverview && query.totalPages > 1 && (
              <div className={styles.pager} aria-label="Reports pagination">
                <Pagination
                  totalPages={query.totalPages}
                  currentPage={query.safePage}
                  onPageChange={(page) => router.push(pageHref(page))}
                />
              </div>
            )}
          </>
        )}
      </Card>
      <ActionConfirmModal
        isOpen={confirm.pendingAction !== null}
        title={confirm.pendingAction?.kind === 'reject' ? tConfirm('rejectionTitle') : tConfirm('approvalTitle')}
        description={
          confirm.pendingAction?.kind === 'reject'
            ? t('confirmList.rejectDescription', { name: confirm.pendingAction.report.name })
            : t('confirmList.approveDescription', { name: confirm.pendingAction?.report.name ?? '' })
        }
        confirmLabel={confirm.pendingAction?.kind === 'reject' ? tConfirm('rejectLabel') : tConfirm('approveLabel')}
        confirmTone={confirm.pendingAction?.kind === 'reject' ? 'danger' : 'default'}
        requireReason={confirm.pendingAction?.kind === 'reject'}
        reasonOptions={rejectionReasonOptions}
        selectedReason={confirm.rejectionReason}
        reasonError={confirm.rejectionReasonError}
        notesValue={confirm.rejectionNotes}
        reasonLabel={tRejection('label')}
        notesLabel={tRejection('notesLabel')}
        notesPlaceholder={tRejection('notesPlaceholder')}
        cancelLabel={tCommon('cancel')}
        onSelectedReasonChange={(value) => {
          confirm.setRejectionReason(value);
          if (confirm.rejectionReasonError) confirm.setRejectionReasonError(null);
        }}
        onNotesChange={confirm.setRejectionNotes}
        onCancel={confirm.closeConfirmModal}
        onConfirm={() => void confirm.confirmAction()}
        isConfirming={confirm.isConfirming}
      />
    </motion.section>
  );
}

export function ReportsList({
  reports,
  variant = 'full',
  embedded = false,
  maxRows = REPORTS_LIST_OVERVIEW_MAX_ROWS,
  prioritizePending = false,
  serverMeta,
  initialSearch,
  siteIdFilter,
  queueSummary,
}: ReportsListProps) {
  return (
    <Suspense fallback={<ReportsListSkeleton embedded={embedded} />}>
      <ReportsListInner
        reports={reports}
        variant={variant}
        embedded={embedded}
        maxRows={maxRows}
        prioritizePending={prioritizePending}
        {...(serverMeta ? { serverMeta } : {})}
        {...(initialSearch !== undefined ? { initialSearch } : {})}
        {...(siteIdFilter ? { siteIdFilter } : {})}
        {...(queueSummary ? { queueSummary } : {})}
      />
    </Suspense>
  );
}
