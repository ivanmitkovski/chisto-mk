'use client';

import { Suspense, useCallback, useEffect, useMemo, useRef, useState } from 'react';
import Link from 'next/link';
import { useRouter, useSearchParams } from 'next/navigation';
import { motion, useReducedMotion } from 'framer-motion';
import { Card, Icon, Pagination, Snack } from '@/components/ui';
import { ADMIN_SEARCH_DEBOUNCE_MS } from '@/lib/admin-ui-timing';
import { subscribeNewReportSignal } from '@/lib/realtime-signals';
import type { ReportRow, SortKey, SortDirection } from '@/features/reports/types';
import { rejectionReasonOptions } from '../constants/rejection-reasons';
import { useReportsListActions } from '../hooks/use-reports-list-actions';
import { ReportListCard, ReportListMobileCard } from './report-list-card';
import { ActionConfirmModal } from './action-confirm-modal';
import { columns, statusFilterOptions } from '../config/table';
import {
  buildReportsUrl,
  REPORTS_LIST_OVERVIEW_MAX_ROWS,
  REPORTS_LIST_PAGE_SIZE,
  sortReports,
  VALID_SORT_KEYS,
} from './reports-list-utils';
import { ReportsListEmptyState } from './reports-list/reports-list-empty-state';
import { ReportsListQueueHeader } from './reports-list/reports-list-queue-header';
import { ReportsListSkeleton } from './reports-list/reports-list-skeleton';
import { ReportsListToolbar } from './reports-list/reports-list-toolbar';
import styles from './reports-list.module.css';

type PendingAction =
  | { kind: 'approve'; report: ReportRow }
  | { kind: 'reject'; report: ReportRow };

const STATUS_FILTERS = statusFilterOptions.filter((f) => f.key !== 'DUPLICATES');
const REFRESH_DEBOUNCE_MS = 800;
const HIGHLIGHT_MS = 7000;

type ReportsListProps = {
  reports: ReportRow[];
  variant?: 'overview' | 'full';
  embedded?: boolean;
  maxRows?: number;
  prioritizePending?: boolean;
};

function ReportsListInner({
  reports,
  variant = 'full',
  embedded = false,
  maxRows = REPORTS_LIST_OVERVIEW_MAX_ROWS,
  prioritizePending = false,
}: ReportsListProps) {
  const router = useRouter();
  const searchParams = useSearchParams();
  const isOverview = variant === 'overview';

  const [searchTerm, setSearchTerm] = useState('');
  const [debouncedSearch, setDebouncedSearch] = useState('');

  const [localStatusFilter, setLocalStatusFilter] = useState<string>('ALL');
  const [localSortKey, setLocalSortKey] = useState<SortKey>('dateReportedAt');
  const [localSortDirection, setLocalSortDirection] = useState<SortDirection>('desc');

  const statusParam = isOverview ? localStatusFilter : (searchParams.get('status') as string | null);
  const sortParam = isOverview ? localSortKey : (searchParams.get('sort') as SortKey | null);
  const dirParam = isOverview ? localSortDirection : (searchParams.get('dir') as SortDirection | null);
  const pageParam = isOverview ? '1' : searchParams.get('page');

  const sortKey: SortKey =
    sortParam && VALID_SORT_KEYS.includes(sortParam) ? sortParam : 'dateReportedAt';
  const sortDirection: SortDirection = dirParam === 'asc' ? 'asc' : 'desc';
  const currentPage = Math.max(1, Number.parseInt(String(pageParam), 10) || 1);

  useEffect(() => {
    const t = window.setTimeout(() => setDebouncedSearch(searchTerm), ADMIN_SEARCH_DEBOUNCE_MS);
    return () => window.clearTimeout(t);
  }, [searchTerm]);

  const filteredByStatus = useMemo(() => {
    if (!statusParam || statusParam === 'ALL') return reports;
    return reports.filter((r) => r.status === statusParam);
  }, [reports, statusParam]);

  const filteredReports = useMemo(() => {
    if (!debouncedSearch.trim()) return filteredByStatus;
    const q = debouncedSearch.trim().toLowerCase();
    return filteredByStatus.filter(
      (r) =>
        r.name.toLowerCase().includes(q) ||
        r.location.toLowerCase().includes(q) ||
        r.reportNumber.toLowerCase().includes(q),
    );
  }, [filteredByStatus, debouncedSearch]);

  const sortedReports = useMemo(
    () => sortReports(filteredReports, sortKey, sortDirection, prioritizePending),
    [filteredReports, sortKey, sortDirection, prioritizePending],
  );

  const pageSize = isOverview ? maxRows : REPORTS_LIST_PAGE_SIZE;
  const effectiveTotalPages = Math.max(1, Math.ceil(sortedReports.length / pageSize));
  const effectiveSafePage = Math.min(currentPage, effectiveTotalPages);

  const duplicateCount = useMemo(
    () => reports.filter((r) => r.isPotentialDuplicate).length,
    [reports],
  );

  const needAttentionCount = useMemo(
    () => reports.filter((r) => r.status === 'NEW' || r.status === 'IN_REVIEW').length,
    [reports],
  );

  const totalPages = effectiveTotalPages;
  const safePage = effectiveSafePage;
  const paginatedReports = useMemo(
    () => sortedReports.slice((safePage - 1) * pageSize, safePage * pageSize),
    [sortedReports, safePage, pageSize],
  );

  const activeFilter = statusParam && STATUS_FILTERS.some((f) => f.key === statusParam) ? statusParam : 'ALL';
  const reducedMotion = useReducedMotion();
  const SPRING = { type: 'spring' as const, stiffness: 400, damping: 30 };
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [highlightedReportIds, setHighlightedReportIds] = useState<Set<string>>(new Set());
  const [pendingAction, setPendingAction] = useState<PendingAction | null>(null);
  const [rejectionReason, setRejectionReason] = useState('');
  const [rejectionNotes, setRejectionNotes] = useState('');
  const [rejectionReasonError, setRejectionReasonError] = useState<string | null>(null);
  const lastRefreshRef = useRef(0);
  const seenReportIdsRef = useRef<Set<string>>(new Set());
  const highlightTimeoutsRef = useRef<Map<string, number>>(new Map());
  const signaledReportIdRef = useRef<string | null>(null);

  const { approveReport, rejectReport, snack, clearSnack } = useReportsListActions();

  useEffect(() => {
    return subscribeNewReportSignal(({ reportId }) => {
      signaledReportIdRef.current = reportId;
    });
  }, []);

  useEffect(() => {
    const currentIds = new Set(reports.map((r) => r.id));

    if (seenReportIdsRef.current.size === 0) {
      seenReportIdsRef.current = currentIds;
      return;
    }

    const newlySeenIds = reports
      .map((r) => r.id)
      .filter((id) => !seenReportIdsRef.current.has(id));

    const signaledId = signaledReportIdRef.current;
    if (signaledId && currentIds.has(signaledId) && !newlySeenIds.includes(signaledId)) {
      newlySeenIds.unshift(signaledId);
    }

    if (newlySeenIds.length > 0) {
      setHighlightedReportIds((prev) => {
        const next = new Set(prev);
        for (const id of newlySeenIds) {
          next.add(id);
          const existing = highlightTimeoutsRef.current.get(id);
          if (existing != null) window.clearTimeout(existing);
          const timeoutId = window.setTimeout(() => {
            setHighlightedReportIds((current) => {
              if (!current.has(id)) return current;
              const updated = new Set(current);
              updated.delete(id);
              return updated;
            });
            highlightTimeoutsRef.current.delete(id);
          }, HIGHLIGHT_MS);
          highlightTimeoutsRef.current.set(id, timeoutId);
        }
        return next;
      });
    }

    seenReportIdsRef.current = currentIds;
  }, [reports]);

  useEffect(() => {
    return () => {
      for (const timeoutId of highlightTimeoutsRef.current.values()) {
        window.clearTimeout(timeoutId);
      }
      highlightTimeoutsRef.current.clear();
    };
  }, []);

  function openApproveModal(report: ReportRow) {
    setPendingAction({ kind: 'approve', report });
    setRejectionReason('');
    setRejectionNotes('');
    setRejectionReasonError(null);
  }

  function openRejectModal(report: ReportRow) {
    setPendingAction({ kind: 'reject', report });
    setRejectionReason('');
    setRejectionNotes('');
    setRejectionReasonError(null);
  }

  function closeConfirmModal() {
    setPendingAction(null);
    setRejectionReason('');
    setRejectionNotes('');
    setRejectionReasonError(null);
  }

  async function confirmAction() {
    if (!pendingAction) return;
    const { report } = pendingAction;
    if (pendingAction.kind === 'approve') {
      const ok = await approveReport(report.id);
      if (ok) closeConfirmModal();
      return;
    }
    if (!rejectionReason.trim()) {
      setRejectionReasonError('Please select a rejection reason.');
      return;
    }
    const composedReason = rejectionNotes.trim()
      ? `${rejectionReason.trim()}. Notes: ${rejectionNotes.trim()}`
      : rejectionReason.trim();
    const ok = await rejectReport(report.id, composedReason);
    if (ok) closeConfirmModal();
  }

  const handleRefresh = useCallback(() => {
    const now = Date.now();
    if (now - lastRefreshRef.current < REFRESH_DEBOUNCE_MS) return;
    lastRefreshRef.current = now;
    setIsRefreshing(true);
    router.refresh();
    window.setTimeout(() => setIsRefreshing(false), REFRESH_DEBOUNCE_MS);
  }, [router]);

  function sortHref(key: SortKey): string {
    if (isOverview) return '#';
    const nextDir =
      sortKey === key ? (sortDirection === 'asc' ? 'desc' : 'asc') : 'desc';
    return buildReportsUrl({
      status: activeFilter !== 'ALL' ? activeFilter : undefined,
      sort: key,
      dir: nextDir,
      page: safePage > 1 ? safePage : undefined,
    });
  }

  function handleSort(key: SortKey) {
    if (isOverview) {
      const nextDir =
        sortKey === key ? (sortDirection === 'asc' ? 'desc' : 'asc') : 'desc';
      setLocalSortKey(key);
      setLocalSortDirection(nextDir);
    }
  }

  function pageHref(page: number): string {
    if (isOverview) return '#';
    return buildReportsUrl({
      status: activeFilter !== 'ALL' ? activeFilter : undefined,
      sort: sortKey,
      dir: sortDirection,
      page: page > 1 ? page : undefined,
    });
  }

  function sortIconName(key: SortKey) {
    if (sortKey !== key) return 'arrow-up-down';
    return sortDirection === 'asc' ? 'chevron-up' : 'chevron-down';
  }

  function ariaSortValue(key: SortKey): 'none' | 'ascending' | 'descending' {
    if (sortKey !== key) return 'none';
    return sortDirection === 'asc' ? 'ascending' : 'descending';
  }

  const sublineText =
    needAttentionCount > 0
      ? `${needAttentionCount} report${needAttentionCount !== 1 ? 's' : ''} need attention`
      : totalPages > 1
        ? `Showing ${(safePage - 1) * pageSize + 1}–${Math.min(safePage * pageSize, sortedReports.length)} of ${sortedReports.length}`
        : `${sortedReports.length} of ${reports.length} report${reports.length !== 1 ? 's' : ''}`;

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
          reportsCount={reports.length}
          needAttentionCount={needAttentionCount}
          duplicateCount={duplicateCount}
          isRefreshing={isRefreshing}
          onRefresh={handleRefresh}
          sublineText={sublineText}
        />
      )}
      <ReportsListToolbar
        isOverview={isOverview}
        searchTerm={searchTerm}
        onSearchTermChange={setSearchTerm}
        onClearSearch={() => setSearchTerm('')}
        statusFilters={STATUS_FILTERS}
        activeFilter={activeFilter}
        onOverviewFilterSelect={setLocalStatusFilter}
        sortKey={sortKey}
        sortDirection={sortDirection}
        safePage={safePage}
      />
      <Card as="div" padding="sm" className={styles.tableCard}>
        {sortedReports.length === 0 ? (
          <ReportsListEmptyState
            totalReportsCount={reports.length}
            filteredByStatusCount={filteredByStatus.length}
            debouncedSearch={debouncedSearch}
          />
        ) : (
          <>
            <div className={styles.tableWrapper}>
              <div className={styles.table}>
                <div className={styles.tableHeader} role="row">
                  {columns.map((col) => (
                    <span key={col.key} className={styles.headerCell}>
                      {isOverview ? (
                        <button
                          type="button"
                          className={styles.headerSortLink}
                          aria-sort={ariaSortValue(col.key)}
                          onClick={() => handleSort(col.key)}
                        >
                          {col.label}
                          <Icon name={sortIconName(col.key)} size={13} className={styles.headerSortIcon} aria-hidden />
                        </button>
                      ) : (
                        <Link
                          href={sortHref(col.key)}
                          className={styles.headerSortLink}
                          aria-sort={ariaSortValue(col.key)}
                        >
                          {col.label}
                          <Icon name={sortIconName(col.key)} size={13} className={styles.headerSortIcon} aria-hidden />
                        </Link>
                      )}
                    </span>
                  ))}
                  <span className={`${styles.headerCell} ${styles.actionsHeader}`}>Actions</span>
                </div>
                <div className={styles.rowList} role="list">
                  {paginatedReports.map((report, index) => (
                    <motion.div
                      key={report.id}
                      className={`${styles.tableRow} ${highlightedReportIds.has(report.id) ? styles.tableRowNew : ''}`}
                      initial={reducedMotion ? false : { opacity: 0, y: 10 }}
                      animate={{ opacity: 1, y: 0 }}
                      transition={
                        reducedMotion
                          ? { duration: 0 }
                          : { type: 'spring', stiffness: 400, damping: 30, delay: Math.min(index * 0.03, 0.15) }
                      }
                    >
                      <ReportListCard
                        report={report}
                        onApprove={openApproveModal}
                        onReject={openRejectModal}
                      />
                    </motion.div>
                  ))}
                </div>
              </div>
            </div>
            <div className={styles.mobileList} role="list">
              {paginatedReports.map((report, index) => (
                <div
                  key={`mobile-wrap-${report.id}`}
                  className={highlightedReportIds.has(report.id) ? styles.mobileRowNew : undefined}
                >
                  <ReportListMobileCard
                    key={`mobile-${report.id}`}
                    report={report}
                    index={index}
                    reducedMotion={!!reducedMotion}
                    onApprove={openApproveModal}
                    onReject={openRejectModal}
                  />
                </div>
              ))}
            </div>
            {!isOverview && totalPages > 1 && (
              <div className={styles.pager} aria-label="Reports pagination">
                <Pagination
                  totalPages={totalPages}
                  currentPage={safePage}
                  onPageChange={(page) => router.push(pageHref(page))}
                />
              </div>
            )}
          </>
        )}
      </Card>
      <Snack snack={snack} onClose={clearSnack} />
      <ActionConfirmModal
        isOpen={pendingAction !== null}
        title={pendingAction?.kind === 'reject' ? 'Confirm rejection' : 'Confirm approval'}
        description={
          pendingAction?.kind === 'reject'
            ? `Reject "${pendingAction.report.name}"? A reason is required.`
            : `Approve "${pendingAction?.report.name ?? ''}" and move it to approved state?`
        }
        confirmLabel={pendingAction?.kind === 'reject' ? 'Reject report' : 'Approve report'}
        confirmTone={pendingAction?.kind === 'reject' ? 'danger' : 'default'}
        requireReason={pendingAction?.kind === 'reject'}
        reasonOptions={rejectionReasonOptions}
        selectedReason={rejectionReason}
        reasonError={rejectionReasonError}
        notesValue={rejectionNotes}
        onSelectedReasonChange={(value) => {
          setRejectionReason(value);
          if (rejectionReasonError) setRejectionReasonError(null);
        }}
        onNotesChange={setRejectionNotes}
        onCancel={closeConfirmModal}
        onConfirm={confirmAction}
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
}: ReportsListProps) {
  return (
    <Suspense fallback={<ReportsListSkeleton embedded={embedded} />}>
      <ReportsListInner
        reports={reports}
        variant={variant}
        embedded={embedded}
        maxRows={maxRows}
        prioritizePending={prioritizePending}
      />
    </Suspense>
  );
}

