import { useEffect, useMemo, useState } from 'react';
import { SnackState } from '@/components/ui';
import { ReportRow, ReportStatus, SortDirection, SortKey, StatusFilter } from '../types';

type ReportTableAction = 'approve' | 'reject';

type UseReportTableOptions = {
  initialRows: ReportRow[];
  pageSize?: number;
};

function normalize(value: string) {
  return value.trim().toLowerCase();
}

export function useReportTable({ initialRows, pageSize = 5 }: UseReportTableOptions) {
  const [rows, setRows] = useState<ReportRow[]>(initialRows);
  const [searchTerm, setSearchTerm] = useState('');
  const [currentPage, setCurrentPage] = useState(1);
  const [snack, setSnack] = useState<SnackState | null>(null);
  const [statusFilter, setStatusFilter] = useState<StatusFilter>('ALL');
  const [sortKey, setSortKey] = useState<SortKey>('dateReportedAt');
  const [sortDirection, setSortDirection] = useState<SortDirection>('desc');

  const visibleRows = useMemo(() => {
    const query = normalize(searchTerm);

    const matchedRows = rows.filter((row) => {
      const matchesQuery =
        !query ||
        normalize(row.reportNumber).includes(query) ||
        normalize(row.name).includes(query) ||
        normalize(row.location).includes(query) ||
        normalize(row.status).includes(query);

      const matchesStatus = statusFilter === 'ALL' || row.status === statusFilter;

      return matchesQuery && matchesStatus;
    });

    const sortedRows = [...matchedRows].sort((leftRow, rightRow) => {
      const modifier = sortDirection === 'asc' ? 1 : -1;

      if (sortKey === 'dateReportedAt') {
        return (new Date(leftRow.dateReportedAt).getTime() - new Date(rightRow.dateReportedAt).getTime()) * modifier;
      }

      if (sortKey === 'reportNumber') {
        const leftNumber = Number.parseInt(leftRow.reportNumber, 10);
        const rightNumber = Number.parseInt(rightRow.reportNumber, 10);
        return (leftNumber - rightNumber) * modifier;
      }

      if (sortKey === 'status') {
        return leftRow.status.localeCompare(rightRow.status) * modifier;
      }

      return leftRow[sortKey].localeCompare(rightRow[sortKey]) * modifier;
    });

    return sortedRows;
  }, [rows, searchTerm, statusFilter, sortKey, sortDirection]);

  const totalPages = Math.max(1, Math.ceil(visibleRows.length / pageSize));
  const safePage = Math.min(currentPage, totalPages);

  const paginatedRows = useMemo(() => {
    const start = (safePage - 1) * pageSize;
    return visibleRows.slice(start, start + pageSize);
  }, [visibleRows, pageSize, safePage]);

  useEffect(() => {
    if (!snack) {
      return undefined;
    }

    const timeoutId = window.setTimeout(() => {
      setSnack(null);
    }, 2400);

    return () => window.clearTimeout(timeoutId);
  }, [snack]);

  function updateStatus(id: string, status: ReportStatus, action: ReportTableAction, reason?: string) {
    let isUpdated = false;

    setRows((prevRows) =>
      prevRows.map((row) => {
        if (row.id !== id) {
          return row;
        }

        isUpdated = true;
        return { ...row, status };
      }),
    );

    if (!isUpdated) {
      setSnack({
        tone: 'error',
        title: 'Action failed',
        message: 'Unable to update this report right now.',
      });
      return;
    }

    if (action === 'approve') {
      setSnack({
        tone: 'success',
        title: 'Report approved',
        message: 'The report has been accepted and moved to approved state.',
      });
      return;
    }

    setSnack({
      tone: 'warning',
      title: 'Report rejected',
      message: reason
        ? `The report has been rejected. Reason: ${reason}`
        : 'The report has been rejected and marked as removed.',
    });
  }

  function handleSearch(value: string) {
    setSearchTerm(value);
    setCurrentPage(1);
  }

  function handleStatusFilter(value: StatusFilter) {
    setStatusFilter(value);
    setCurrentPage(1);
  }

  function handleSort(nextSortKey: SortKey) {
    if (sortKey === nextSortKey) {
      setSortDirection((prevDirection) => (prevDirection === 'asc' ? 'desc' : 'asc'));
      return;
    }

    setSortKey(nextSortKey);
    setSortDirection(nextSortKey === 'dateReportedAt' ? 'desc' : 'asc');
  }

  function handlePageChange(page: number) {
    setCurrentPage(Math.min(Math.max(page, 1), totalPages));
  }

  return {
    paginatedRows,
    searchTerm,
    snack,
    totalPages,
    currentPage: safePage,
    sortKey,
    sortDirection,
    statusFilter,
    totalCount: rows.length,
    visibleCount: visibleRows.length,
    hasRows: rows.length > 0,
    hasFilteredRows: visibleRows.length > 0,
    handleSearch,
    handleStatusFilter,
    handleSort,
    handlePageChange,
    approveReport: (id: string) => updateStatus(id, 'APPROVED', 'approve'),
    rejectReport: (id: string, reason?: string) => updateStatus(id, 'DELETED', 'reject', reason),
    clearSnack: () => setSnack(null),
  };
}
