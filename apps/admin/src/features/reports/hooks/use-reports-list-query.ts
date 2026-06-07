'use client';

import { useEffect, useMemo, useState } from 'react';
import { useTranslations } from 'next-intl';
import { useRouter, useSearchParams } from 'next/navigation';
import { ADMIN_SEARCH_DEBOUNCE_MS } from '@/lib/utils';
import type { ReportRow, SortDirection, SortKey } from '@/features/reports/types';
import type { ReportsQueueSummary } from '@/features/reports/data/reports-adapter';
import { STATUS_FILTER_KEYS } from '@/features/reports/config/table';
import {
  REPORTS_LIST_OVERVIEW_MAX_ROWS,
  REPORTS_LIST_PAGE_SIZE,
  buildReportsUrl,
  sortReports,
  VALID_SORT_KEYS,
} from '@/features/reports/components/reports-list-utils';

export { STATUS_FILTER_KEYS as REPORTS_STATUS_FILTER_KEYS } from '@/features/reports/config/table';

type ServerMeta = { page: number; limit: number; total: number };

type UseReportsListQueryOptions = {
  reports: ReportRow[];
  variant?: 'overview' | 'full';
  maxRows?: number;
  prioritizePending?: boolean;
  serverMeta?: ServerMeta;
  initialSearch?: string;
  siteIdFilter?: string;
  queueSummary?: ReportsQueueSummary;
};

function listUrlParams(input: {
  statusParam: string | null;
  duplicatesOnly: boolean;
  sortKey: SortKey;
  sortDirection: SortDirection;
  debouncedSearch: string;
  siteIdFilter?: string;
  page?: number;
}) {
  const isDuplicatesFilter = input.duplicatesOnly || input.statusParam === 'DUPLICATES';
  return buildReportsUrl({
    status:
      input.statusParam && input.statusParam !== 'ALL' && input.statusParam !== 'DUPLICATES'
        ? input.statusParam
        : undefined,
    sort: input.sortKey,
    dir: input.sortDirection,
    page: input.page,
    search: input.debouncedSearch.trim() || undefined,
    siteId: input.siteIdFilter,
    duplicatesOnly: isDuplicatesFilter ? true : undefined,
  });
}

export function useReportsListQuery({
  reports,
  variant = 'full',
  maxRows = REPORTS_LIST_OVERVIEW_MAX_ROWS,
  prioritizePending = false,
  serverMeta,
  initialSearch = '',
  siteIdFilter,
  queueSummary,
}: UseReportsListQueryOptions) {
  const t = useTranslations('reports');
  const tQueue = useTranslations('reports.queue');
  const router = useRouter();
  const searchParams = useSearchParams();
  const isOverview = variant === 'overview';
  const isServerPaginated = !isOverview && serverMeta != null;

  const [searchTerm, setSearchTerm] = useState(initialSearch);
  const [debouncedSearch, setDebouncedSearch] = useState(initialSearch);
  const [localStatusFilter, setLocalStatusFilter] = useState<string>('ALL');
  const [localSortKey, setLocalSortKey] = useState<SortKey>('dateReportedAt');
  const [localSortDirection, setLocalSortDirection] = useState<SortDirection>('desc');
  const [localDuplicatesOnly, setLocalDuplicatesOnly] = useState(false);

  const statusParam = isOverview ? localStatusFilter : (searchParams.get('status') as string | null);
  const duplicatesOnly = isOverview
    ? localDuplicatesOnly || localStatusFilter === 'DUPLICATES'
    : searchParams.get('duplicatesOnly') === 'true' || searchParams.get('duplicatesOnly') === '1';
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

  useEffect(() => {
    if (!isServerPaginated) return;
    const urlSearch = searchParams.get('search') ?? '';
    if (debouncedSearch.trim() === urlSearch.trim()) return;
    router.push(
      listUrlParams({
        statusParam,
        duplicatesOnly,
        sortKey,
        sortDirection,
        debouncedSearch,
        ...(siteIdFilter ? { siteIdFilter } : {}),
      }),
    );
  }, [
    debouncedSearch,
    duplicatesOnly,
    isServerPaginated,
    router,
    searchParams,
    siteIdFilter,
    sortDirection,
    sortKey,
    statusParam,
  ]);

  const filteredByStatus = useMemo(() => {
    if (isServerPaginated) return reports;
    if (duplicatesOnly) return reports.filter((r) => r.isPotentialDuplicate);
    if (!statusParam || statusParam === 'ALL' || statusParam === 'DUPLICATES') return reports;
    return reports.filter((r) => r.status === statusParam);
  }, [duplicatesOnly, isServerPaginated, reports, statusParam]);

  const filteredReports = useMemo(() => {
    if (isServerPaginated) return filteredByStatus;
    if (!debouncedSearch.trim()) return filteredByStatus;
    const q = debouncedSearch.trim().toLowerCase();
    return filteredByStatus.filter(
      (r) =>
        r.name.toLowerCase().includes(q) ||
        r.location.toLowerCase().includes(q) ||
        r.reportNumber.toLowerCase().includes(q),
    );
  }, [debouncedSearch, filteredByStatus, isServerPaginated]);

  const sortedReports = useMemo(() => {
    if (isServerPaginated) return filteredReports;
    return sortReports(filteredReports, sortKey, sortDirection, prioritizePending);
  }, [filteredReports, isServerPaginated, sortKey, sortDirection, prioritizePending]);

  const pageSize = isServerPaginated
    ? serverMeta.limit
    : isOverview
      ? maxRows
      : REPORTS_LIST_PAGE_SIZE;
  const totalItems = isServerPaginated ? serverMeta.total : sortedReports.length;
  const totalPages = Math.max(1, Math.ceil(totalItems / pageSize));
  const safePage = isServerPaginated ? serverMeta.page : Math.min(currentPage, totalPages);

  const duplicateCount = useMemo(
    () => queueSummary?.duplicatesCount ?? reports.filter((r) => r.isPotentialDuplicate).length,
    [queueSummary?.duplicatesCount, reports],
  );

  const needAttentionCount = useMemo(
    () =>
      queueSummary?.needAttentionCount ??
      reports.filter((r) => r.status === 'NEW' || r.status === 'IN_REVIEW').length,
    [queueSummary?.needAttentionCount, reports],
  );

  const paginatedReports = useMemo(() => {
    if (isServerPaginated) return sortedReports;
    return sortedReports.slice((safePage - 1) * pageSize, safePage * pageSize);
  }, [isServerPaginated, pageSize, safePage, sortedReports]);

  const activeFilter = duplicatesOnly
    ? 'DUPLICATES'
    : statusParam && STATUS_FILTER_KEYS.includes(statusParam as import('../types').StatusFilter)
      ? statusParam
      : 'ALL';

  function handleSort(key: SortKey) {
    if (!isOverview) return;
    const nextDir =
      sortKey === key ? (sortDirection === 'asc' ? 'desc' : 'asc') : 'desc';
    setLocalSortKey(key);
    setLocalSortDirection(nextDir);
  }

  function handleOverviewFilterSelect(key: string) {
    setLocalStatusFilter(key);
    setLocalDuplicatesOnly(key === 'DUPLICATES');
  }

  function sortIconName(key: SortKey) {
    if (sortKey !== key) return 'arrow-up-down';
    return sortDirection === 'asc' ? 'chevron-up' : 'chevron-down';
  }

  function ariaSortValue(key: SortKey): 'none' | 'ascending' | 'descending' {
    if (sortKey !== key) return 'none';
    return sortDirection === 'asc' ? 'ascending' : 'descending';
  }

  function filterHref(filterKey: string): string {
    if (isOverview) return '#';
    const isDuplicates = filterKey === 'DUPLICATES';
    return buildReportsUrl({
      status: !isDuplicates && filterKey !== 'ALL' ? filterKey : undefined,
      sort: sortKey,
      dir: sortDirection,
      search: debouncedSearch.trim() || undefined,
      ...(siteIdFilter ? { siteId: siteIdFilter } : {}),
      duplicatesOnly: isDuplicates ? true : undefined,
    });
  }

  function sortHref(key: SortKey): string {
    if (isOverview) return '#';
    const nextDir = sortKey === key ? (sortDirection === 'asc' ? 'desc' : 'asc') : 'desc';
    return listUrlParams({
      statusParam,
      duplicatesOnly,
      sortKey: key,
      sortDirection: nextDir,
      debouncedSearch,
      ...(siteIdFilter ? { siteIdFilter } : {}),
    });
  }

  const sublineText = isServerPaginated
    ? totalItems > 0
      ? tQueue('showingRange', {
          from: (safePage - 1) * pageSize + 1,
          to: Math.min(safePage * pageSize, totalItems),
          total: totalItems,
        })
      : t('empty')
    : needAttentionCount > 0
      ? tQueue('needAttention', { count: needAttentionCount })
      : totalPages > 1
        ? tQueue('showingRange', {
            from: (safePage - 1) * pageSize + 1,
            to: Math.min(safePage * pageSize, sortedReports.length),
            total: sortedReports.length,
          })
        : tQueue('reportsCountFiltered', { shown: sortedReports.length, total: reports.length });

  return {
    isOverview,
    isServerPaginated,
    searchTerm,
    setSearchTerm,
    debouncedSearch,
    sortKey,
    sortDirection,
    safePage,
    totalPages,
    pageSize,
    totalItems,
    sortedReports,
    paginatedReports,
    filteredByStatus,
    duplicateCount,
    needAttentionCount,
    activeFilter,
    duplicatesOnly,
    setLocalStatusFilter: handleOverviewFilterSelect,
    handleSort,
    sortIconName,
    ariaSortValue,
    sublineText,
    siteIdFilter,
    filterHref,
    sortHref,
  };
}
