'use client';

import { useState } from 'react';
import Link from 'next/link';
import { motion } from 'framer-motion';
import { Button, Card, Icon, Input, Pagination, SectionState, Snack } from '@/components/ui';
import { ActionConfirmModal } from './action-confirm-modal';
import { columns, statusFilterOptions } from '../config/table';
import { rejectionReasonOptions } from '../constants/rejection-reasons';
import { useReportTable } from '../hooks/use-report-table';
import { ReportRow, SortKey } from '../types';
import { formatReportDate, formatReportStatus, statusIconName } from '../utils/report-status';
import styles from './reports-table.module.css';

type ReportsTableProps = {
  rows: ReportRow[];
};

type PendingTableAction =
  | {
      kind: 'approve';
      row: ReportRow;
    }
  | {
      kind: 'reject';
      row: ReportRow;
    };

function statusClassName(status: ReportRow['status']) {
  const statusClassByName: Record<ReportRow['status'], string> = {
    NEW: styles.statusNew,
    IN_REVIEW: styles.statusInReview,
    APPROVED: styles.statusApproved,
    DELETED: styles.statusDeleted,
  };

  return `${styles.status} ${statusClassByName[status]}`;
}

function queueMeta(status: ReportRow['status']): { priority: 'Critical' | 'High' | 'Normal'; slaLabel: string } {
  if (status === 'NEW') {
    return { priority: 'Critical', slaLabel: '2h remaining' };
  }

  if (status === 'IN_REVIEW') {
    return { priority: 'High', slaLabel: '1h remaining' };
  }

  if (status === 'APPROVED') {
    return { priority: 'Normal', slaLabel: 'Completed' };
  }

  return { priority: 'Normal', slaLabel: 'Completed' };
}

export function ReportsTable({ rows }: ReportsTableProps) {
  const {
    paginatedRows,
    searchTerm,
    snack,
    sortKey,
    sortDirection,
    statusFilter,
    totalCount,
    visibleCount,
    totalPages,
    currentPage,
    hasRows,
    hasFilteredRows,
    handleSearch,
    handleStatusFilter,
    handleSort,
    handlePageChange,
    approveReport,
    rejectReport,
    clearSnack,
  } = useReportTable({ initialRows: rows });
  const [pendingAction, setPendingAction] = useState<PendingTableAction | null>(null);
  const [rejectionReason, setRejectionReason] = useState('');
  const [rejectionNotes, setRejectionNotes] = useState('');
  const [rejectionReasonError, setRejectionReasonError] = useState<string | null>(null);

  const selectedFilterLabel = statusFilterOptions.find((option) => option.key === statusFilter)?.label ?? 'All';
  const highPriorityCount = rows.filter((row) => {
    const meta = queueMeta(row.status);
    return meta.priority === 'Critical' || meta.priority === 'High';
  }).length;

  function sortIconName(columnKey: SortKey) {
    if (sortKey !== columnKey) {
      return 'arrow-up-down';
    }

    return sortDirection === 'asc' ? 'chevron-up' : 'chevron-down';
  }

  function ariaSortValue(columnKey: SortKey): 'none' | 'ascending' | 'descending' {
    if (sortKey !== columnKey) {
      return 'none';
    }

    return sortDirection === 'asc' ? 'ascending' : 'descending';
  }

  function openApproveModal(row: ReportRow) {
    setPendingAction({ kind: 'approve', row });
    setRejectionReason('');
    setRejectionNotes('');
    setRejectionReasonError(null);
  }

  function openRejectModal(row: ReportRow) {
    setPendingAction({ kind: 'reject', row });
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

  async function confirmTableAction() {
    if (!pendingAction) {
      return;
    }

    if (pendingAction.kind === 'reject') {
      if (!rejectionReason) {
        setRejectionReasonError('Please select a rejection reason.');
        return;
      }

      setRejectionReasonError(null);
      const composedReason = rejectionNotes.trim()
        ? `${rejectionReason}. Notes: ${rejectionNotes.trim()}`
        : rejectionReason;
      await rejectReport(pendingAction.row.id, composedReason);
      closeConfirmModal();
      return;
    }

    await approveReport(pendingAction.row.id);
    closeConfirmModal();
  }

  return (
    <motion.div
      initial={{ opacity: 0, y: 14 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.28, ease: 'easeOut' }}
    >
      <Card className={styles.card}>
        <div className={styles.header}>
          <div className={styles.headingGroup}>
            <h2 className={styles.title}>Reports</h2>
            <p className={styles.subtitle}>
              Showing {visibleCount} of {totalCount} reports
              {statusFilter !== 'ALL' ? ` • ${selectedFilterLabel}` : ''}
              {highPriorityCount > 0 ? ` • ${highPriorityCount} high priority` : ''}
            </p>
          </div>
          <div className={styles.headerControls}>
            <Input
              aria-label="Search reports"
              placeholder="Search by name or location"
              value={searchTerm}
              onChange={(event) => handleSearch(event.target.value)}
              className={styles.search}
              leftSlot={<Icon name="magnifying-glass" size={14} />}
            />
          </div>
        </div>

        <div className={styles.filterRow} role="toolbar" aria-label="Report filters">
          <div className={styles.filterChips}>
            {statusFilterOptions.map((option) => (
              <button
                key={option.key}
                type="button"
                className={`${styles.filterChip} ${statusFilter === option.key ? styles.filterChipActive : ''}`}
                onClick={() => handleStatusFilter(option.key)}
                aria-pressed={statusFilter === option.key}
              >
                {option.label}
              </button>
            ))}
          </div>
        </div>

        {!hasRows ? <SectionState variant="empty" message="No reports available yet." /> : null}
        {hasRows && !hasFilteredRows ? (
          <SectionState variant="empty" message="No reports match your search query." />
        ) : null}

        {hasRows && hasFilteredRows ? (
          <>
            <div className={styles.tableWrapper}>
              <table className={styles.table}>
                <thead>
                  <tr>
                    {columns.map((column) => (
                      <th key={column.key} aria-sort={ariaSortValue(column.key)}>
                        <button type="button" className={styles.headerButton} onClick={() => handleSort(column.key)}>
                          {column.label}
                          <Icon name={sortIconName(column.key)} size={13} className={styles.headerIcon} />
                        </button>
                      </th>
                    ))}
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {paginatedRows.map((row) => (
                    <motion.tr
                      key={row.id}
                      initial={{ opacity: 0, y: 10 }}
                      animate={{ opacity: 1, y: 0 }}
                      transition={{ duration: 0.22 }}
                    >
                      <td>{row.reportNumber}</td>
                      <td>{row.name}</td>
                      <td>{row.location}</td>
                      <td>{formatReportDate(row.dateReportedAt)}</td>
                      <td>
                        {(() => {
                          const meta = queueMeta(row.status);
                          return (
                            <div className={styles.statusCell}>
                              <span className={statusClassName(row.status)}>
                                <Icon name={statusIconName(row.status)} size={12} />
                                {formatReportStatus(row.status)}
                              </span>
                              <div className={styles.queueMeta}>
                                <span
                                  className={`${styles.priorityChip} ${
                                    meta.priority === 'Critical'
                                      ? styles.priorityCritical
                                      : meta.priority === 'High'
                                        ? styles.priorityHigh
                                        : styles.priorityNormal
                                  }`}
                                >
                                  {meta.priority}
                                </span>
                                <span className={styles.slaText}>{meta.slaLabel}</span>
                              </div>
                              {row.isPotentialDuplicate ? (
                                <Link
                                  href={`/dashboard/reports/duplicates?reportId=${row.id}`}
                                  className={styles.duplicateBadge}
                                  aria-label={`View possible duplicates for ${row.reportNumber}`}
                                >
                                  Duplicate
                                  {row.coReporterCount > 0 ? ` (+${row.coReporterCount})` : ''}
                                </Link>
                              ) : null}
                            </div>
                          );
                        })()}
                      </td>
                      <td>
                        <div className={styles.actions}>
                          <Button size="sm" onClick={() => openApproveModal(row)}>
                            <Icon name="check" size={14} />
                            Approve
                          </Button>
                          <Button variant="outline" size="sm" onClick={() => openRejectModal(row)}>
                            <Icon name="trash" size={14} />
                            Reject
                          </Button>
                          <Link
                            href={`/dashboard/reports?reportId=${row.id}`}
                            className={styles.detailsLink}
                            aria-label="Open report details"
                          >
                            <Icon name="document-forward" size={14} />
                          </Link>
                        </div>
                      </td>
                    </motion.tr>
                  ))}
                </tbody>
              </table>
            </div>

            <div className={styles.mobileList}>
              {paginatedRows.map((row) => (
                <motion.article
                  key={`mobile-${row.id}`}
                  className={styles.mobileItem}
                  initial={{ opacity: 0, y: 8 }}
                  animate={{ opacity: 1, y: 0 }}
                  transition={{ duration: 0.22 }}
                >
                  <div className={styles.mobileMeta}>
                    <strong>{row.reportNumber}</strong>
                    <span>{formatReportDate(row.dateReportedAt)}</span>
                  </div>
                  <h3 className={styles.mobileTitle}>{row.name}</h3>
                  <p className={styles.mobileLocation}>
                    <Icon name="location" size={14} />
                    {row.location}
                  </p>
                  <div className={styles.mobileStatusRow}>
                    <span className={statusClassName(row.status)}>
                      <Icon name={statusIconName(row.status)} size={12} />
                      {formatReportStatus(row.status)}
                    </span>
                    {row.isPotentialDuplicate ? (
                      <Link
                        href={`/dashboard/reports/duplicates?reportId=${row.id}`}
                        className={styles.duplicateBadge}
                        aria-label={`View possible duplicates for ${row.reportNumber}`}
                      >
                        Duplicate
                        {row.coReporterCount > 0 ? ` (+${row.coReporterCount})` : ''}
                      </Link>
                    ) : null}
                  </div>
                  <div className={styles.mobileActions}>
                    <Button size="sm" onClick={() => openApproveModal(row)}>
                      <Icon name="check" size={14} />
                      Approve
                    </Button>
                    <Button variant="outline" size="sm" onClick={() => openRejectModal(row)}>
                      <Icon name="trash" size={14} />
                      Reject
                    </Button>
                    <Link
                      href={`/dashboard/reports?reportId=${row.id}`}
                      className={styles.detailsLink}
                      aria-label="Open report details"
                    >
                      <Icon name="document-forward" size={14} />
                    </Link>
                  </div>
                </motion.article>
              ))}
            </div>

            <div className={styles.pager} aria-label="Reports pagination">
              <Pagination totalPages={totalPages} currentPage={currentPage} onPageChange={handlePageChange} />
            </div>
          </>
        ) : null}
        <Snack snack={snack} onClose={clearSnack} />
      </Card>
      <ActionConfirmModal
        isOpen={pendingAction !== null}
        title={pendingAction?.kind === 'reject' ? 'Confirm rejection' : 'Confirm approval'}
        description={
          pendingAction?.kind === 'reject'
            ? `Reject "${pendingAction.row.name}"? A reason is required.`
            : `Approve "${pendingAction?.row.name ?? ''}" and move it to approved state?`
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
          if (rejectionReasonError) {
            setRejectionReasonError(null);
          }
        }}
        onNotesChange={(value) => setRejectionNotes(value)}
        onCancel={closeConfirmModal}
        onConfirm={confirmTableAction}
      />
    </motion.div>
  );
}
