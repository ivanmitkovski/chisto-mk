import type { ReportRow, SortDirection, SortKey } from '@/features/reports/types';

export const REPORTS_LIST_PAGE_SIZE = 10;
export const REPORTS_LIST_OVERVIEW_MAX_ROWS = 5;

export const STATUS_PRIORITY: Record<ReportRow['status'], number> = {
  NEW: 0,
  IN_REVIEW: 1,
  APPROVED: 2,
  DELETED: 3,
};

export const VALID_SORT_KEYS: SortKey[] = [
  'reportNumber',
  'name',
  'location',
  'dateReportedAt',
  'status',
];

export function buildReportsUrl(params: {
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

export function sortReports(
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
