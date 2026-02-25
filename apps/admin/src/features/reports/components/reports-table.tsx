'use client';

import Link from 'next/link';
import { motion } from 'framer-motion';
import { Button, Card, Icon, Input, Pagination, SectionState, Snack } from '@/components/ui';
import { columns, statusFilterOptions } from '../config/table';
import { useReportTable } from '../hooks/use-report-table';
import { ReportRow, SortKey } from '../types';
import { formatReportDate, formatReportStatus, statusIconName } from '../utils/report-status';
import styles from './reports-table.module.css';

type ReportsTableProps = {
  rows: ReportRow[];
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

  const selectedFilterLabel = statusFilterOptions.find((option) => option.key === statusFilter)?.label ?? 'All';

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
                        <span className={statusClassName(row.status)}>
                          <Icon name={statusIconName(row.status)} size={12} />
                          {formatReportStatus(row.status)}
                        </span>
                      </td>
                      <td>
                        <div className={styles.actions}>
                          <Button size="sm" onClick={() => approveReport(row.id)}>
                            <Icon name="check" size={14} />
                            Approve
                          </Button>
                          <Button variant="outline" size="sm" onClick={() => rejectReport(row.id)}>
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
                  <span className={statusClassName(row.status)}>
                    <Icon name={statusIconName(row.status)} size={12} />
                    {formatReportStatus(row.status)}
                  </span>
                  <div className={styles.mobileActions}>
                    <Button size="sm" onClick={() => approveReport(row.id)}>
                      <Icon name="check" size={14} />
                      Approve
                    </Button>
                    <Button variant="outline" size="sm" onClick={() => rejectReport(row.id)}>
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
    </motion.div>
  );
}
