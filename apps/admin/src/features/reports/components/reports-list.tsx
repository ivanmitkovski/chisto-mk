'use client';

import { Suspense, useCallback, useEffect, useMemo, useRef, useState } from 'react';
import Link from 'next/link';
import { useRouter, useSearchParams } from 'next/navigation';
import { motion, useReducedMotion } from 'framer-motion';
import { Button, Card, Icon, Input, Pagination, Snack } from '@/components/ui';
import { ADMIN_SEARCH_DEBOUNCE_MS } from '@/lib/admin-ui-timing';
import { subscribeNewReportSignal } from '@/lib/realtime-signals';
import type { ReportRow, SortKey, SortDirection } from '@/features/reports/types';
import { rejectionReasonOptions } from '../constants/rejection-reasons';
import { useReportsListActions } from '../hooks/use-reports-list-actions';
import { ReportListCard, ReportListMobileCard } from './report-list-card';
import { ActionConfirmModal } from './action-confirm-modal';
import { columns, statusFilterOptions } from '../config/table';
import styles from './reports-list.module.css';

type PendingAction =
  | { kind: 'approve'; report: ReportRow }
  | { kind: 'reject'; report: ReportRow };

const STATUS_FILTERS = statusFilterOptions.filter((f) => f.key !== 'DUPLICATES');
const PAGE_SIZE = 10;
const OVERVIEW_MAX_ROWS = 5;
const STATUS_PRIORITY: Record<ReportRow['status'], number> = {
  NEW: 0,
  IN_REVIEW: 1,
  APPROVED: 2,
  DELETED: 3,
};
const VALID_SORT_KEYS: SortKey[] = ['reportNumber', 'name', 'location', 'dateReportedAt', 'status'];
const REFRESH_DEBOUNCE_MS = 800;
const HIGHLIGHT_MS = 7000;

function buildReportsUrl(params: {
  status?: string | undefined;
  sort?: SortKey | undefined;
  dir?: SortDirection | undefined;
  page?: number | undefined;
}) {
  const sp = new URLSearchParams();
  if (params.status && params.status !== 'ALL') sp.set('status', params.status);
  if (params.sort) sp.set('sort', params.sort);
  if (params.dir) sp.set('dir', params.dir);
  if (params.page && params.page > 1) sp.set('page', String(params.page));
  const q = sp.toString();
  return `/dashboard/reports${q ? `?${q}` : ''}`;
}

function sortReports(
  rows: ReportRow[],
  sortKey: SortKey,
  sortDirection: SortDirection,
  prioritizePending = false,
): ReportRow[] {
  const modifier = sortDirection === 'asc' ? 1 : -1;
  return [...rows].sort((a, b) => {
    if (prioritizePending) {
      const aPri = STATUS_PRIORITY[a.status];
      const bPri = STATUS_PRIORITY[b.status];
      if (aPri !== bPri) return aPri - bPri;
    }
    if (sortKey === 'dateReportedAt') {
      return (
        (new Date(a.dateReportedAt).getTime() - new Date(b.dateReportedAt).getTime()) * modifier
      );
    }
    if (sortKey === 'reportNumber') {
      const an = Number.parseInt(a.reportNumber, 10);
      const bn = Number.parseInt(b.reportNumber, 10);
      if (!Number.isNaN(an) && !Number.isNaN(bn)) return (an - bn) * modifier;
      return a.reportNumber.localeCompare(b.reportNumber) * modifier;
    }
    if (sortKey === 'status') {
      return a.status.localeCompare(b.status) * modifier;
    }
    return a[sortKey].localeCompare(b[sortKey]) * modifier;
  });
}

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
  maxRows = OVERVIEW_MAX_ROWS,
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

  const pageSize = isOverview ? maxRows : PAGE_SIZE;
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
      await approveReport(report.id);
    } else {
      if (!rejectionReason.trim()) {
        setRejectionReasonError('Please select a rejection reason.');
        return;
      }
      await rejectReport(report.id, rejectionReason.trim());
    }
    closeConfirmModal();
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
        ? `Showing ${(safePage - 1) * PAGE_SIZE + 1}–${Math.min(safePage * PAGE_SIZE, sortedReports.length)} of ${sortedReports.length}`
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
        <>
          <div className={styles.summaryStrip}>
            <span className={styles.summaryValue}>{reports.length} reports</span>
            <span className={styles.summarySep}>·</span>
            <span className={styles.summaryValue}>{needAttentionCount} need attention</span>
            <span className={styles.summarySep}>·</span>
            <Link href="/dashboard/reports/duplicates" className={styles.summaryLink}>
              {duplicateCount} duplicate{duplicateCount !== 1 ? 's' : ''}
            </Link>
          </div>
          <span className={styles.sectionLabel}>Queue</span>
          <div className={styles.reportsHeader}>
            <div>
              <h2 id="reports-heading" className={styles.sectionTitle}>
                Reports
              </h2>
              <p className={styles.reportsSubline} data-attention={needAttentionCount > 0 ? 'true' : undefined}>
                {sublineText}
              </p>
            </div>
            <div className={styles.reportsHeaderActions}>
              <div className={styles.statusPill} role="status">
                <Button
                  variant="icon"
                  aria-label="Refresh reports"
                  onClick={handleRefresh}
                  disabled={isRefreshing}
                  className={styles.refreshBtn}
                >
                  <Icon
                    name="refresh"
                    size={16}
                    {...(isRefreshing && { className: styles.spinning })}
                  />
                </Button>
              </div>
              <Link href="/dashboard/reports/duplicates" className={styles.viewAllLink}>
                {duplicateCount > 0 ? `${duplicateCount} potential duplicate${duplicateCount !== 1 ? 's' : ''}` : 'Duplicates'}
                <Icon name="chevron-right" size={12} className={styles.linkChevron} aria-hidden />
              </Link>
            </div>
          </div>
        </>
      )}
      <div className={styles.toolbar} role="toolbar" aria-label="Filter and search">
        <Input
          aria-label="Search reports by name, location, or number"
          placeholder="Search reports…"
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          className={styles.search}
          leftSlot={<Icon name="magnifying-glass" size={14} aria-hidden />}
          rightSlot={
            searchTerm ? (
              <button
                type="button"
                className={styles.clearSearchBtn}
                onClick={() => setSearchTerm('')}
                aria-label="Clear search"
              >
                <Icon name="x" size={14} aria-hidden />
              </button>
            ) : null
          }
        />
        <div className={styles.filterRow} role="group" aria-label="Filter by status">
          <div className={styles.filterChips}>
            {STATUS_FILTERS.map((opt) =>
              isOverview ? (
                <button
                  key={opt.key}
                  type="button"
                  className={`${styles.filterChip} ${activeFilter === opt.key ? styles.filterChipActive : ''}`}
                  onClick={() => setLocalStatusFilter(opt.key)}
                  aria-pressed={activeFilter === opt.key}
                >
                  {opt.label}
                </button>
              ) : (
                <Link
                  key={opt.key}
                  href={buildReportsUrl({
                    status: opt.key !== 'ALL' ? opt.key : undefined,
                    sort: sortKey,
                    dir: sortDirection,
                    page: safePage > 1 ? safePage : undefined,
                  })}
                  className={`${styles.filterChip} ${activeFilter === opt.key ? styles.filterChipActive : ''}`}
                  aria-current={activeFilter === opt.key ? 'page' : undefined}
                >
                  {opt.label}
                </Link>
              ),
            )}
          </div>
        </div>
      </div>
      <Card as="div" padding="sm" className={styles.tableCard}>
        {sortedReports.length === 0 ? (
          <div className={styles.emptyState}>
            {reports.length === 0 ? (
              <>
                <Icon name="document-text" size={40} className={styles.emptyStateIcon} aria-hidden />
                <p>No reports yet. Share the Chisto app or reporting link with citizens to get started.</p>
              </>
            ) : filteredByStatus.length === 0 ? (
              <>
                <Icon name="document-duplicate" size={40} className={styles.emptyStateIcon} aria-hidden />
                <p>No reports match the selected filter.</p>
              </>
            ) : (
              <>
                <Icon name="magnifying-glass" size={40} className={styles.emptyStateIcon} aria-hidden />
                <p>No reports match &ldquo;{debouncedSearch}&rdquo;.</p>
                <p className={styles.emptyStateHint}>Try a different search term or clear the search.</p>
              </>
            )}
          </div>
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
  maxRows = OVERVIEW_MAX_ROWS,
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

function ReportsListSkeleton({ embedded = false }: { embedded?: boolean }) {
  if (embedded) {
    return (
      <div className={styles.section} aria-busy="true">
        <div className={styles.toolbar}>
          <div className={styles.filterRow}>
            <div className={styles.filterChips}>
              {[1, 2, 3, 4, 5].map((i) => (
                <span key={i} className={styles.filterChipSkeleton} />
              ))}
            </div>
          </div>
        </div>
        <Card as="div" padding="sm" className={styles.tableCard}>
          <div className={styles.tableSkeleton}>
            {Array.from({ length: 5 }).map((_, i) => (
              <div key={i} className={styles.rowSkeleton} />
            ))}
          </div>
        </Card>
      </div>
    );
  }
  return (
    <section className={styles.section} aria-busy="true">
      <div className={styles.summaryStrip}>
        <span className={styles.summaryValue}>—</span>
        <span className={styles.summarySep}>·</span>
        <span className={styles.summaryValue}>—</span>
        <span className={styles.summarySep}>·</span>
        <span className={styles.summaryValue}>—</span>
      </div>
      <span className={styles.sectionLabel}>Queue</span>
      <div className={styles.reportsHeader}>
        <div>
          <div className={styles.titleSkeleton} />
          <div className={styles.subtitleSkeleton} />
        </div>
      </div>
      <div className={styles.toolbar}>
        <div className={styles.filterRow}>
          <div className={styles.filterChips}>
            {[1, 2, 3, 4, 5].map((i) => (
              <span key={i} className={styles.filterChipSkeleton} />
            ))}
          </div>
        </div>
      </div>
      <Card as="div" padding="sm" className={styles.tableCard}>
        <div className={styles.tableSkeleton}>
          {Array.from({ length: 6 }).map((_, i) => (
            <div key={i} className={styles.rowSkeleton} />
          ))}
        </div>
      </Card>
    </section>
  );
}
