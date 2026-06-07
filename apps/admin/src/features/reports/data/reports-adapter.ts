import { serverAuthenticatedFetch } from '@/lib/auth/server-api-with-refresh';
import type { Schema } from '@/lib/api';
import type { SortDirection, SortKey } from '../types';
import { DuplicateReportGroup, ReportDetail, ReportRow } from '../types';

type AdminReportListItem = Schema<'AdminReportListItemDto'>;
type AdminReportListResponse = Schema<'AdminReportListResponseDto'>;
type DuplicateReportGroupsResponse = Schema<'AdminDuplicateReportGroupsResponseDto'>;

export type ReportsQueueSummary = {
  total: number;
  needAttentionCount: number;
  duplicatesCount: number;
  byStatus: Record<string, number>;
};

function mapAdminReportListItem(item: AdminReportListItem): ReportRow {
  return {
    id: item.id,
    reportNumber: item.reportNumber,
    name: item.name,
    location: item.location,
    dateReportedAt: item.dateReportedAt,
    status: item.status,
    isPotentialDuplicate: item.isPotentialDuplicate,
    coReporterCount: item.coReporterCount,
    cleanupEffortLabel: typeof item.cleanupEffortLabel === 'string' ? item.cleanupEffortLabel : null,
  };
}

export async function getReportsPage(params?: {
  siteId?: string;
  page?: number;
  limit?: number;
  status?: string;
  search?: string;
  q?: string;
  sort?: SortKey;
  dir?: SortDirection;
  duplicatesOnly?: boolean;
}): Promise<{ data: ReportRow[]; meta: { page: number; limit: number; total: number } }> {
  const search = new URLSearchParams();
  search.set('page', String(params?.page ?? 1));
  search.set('limit', String(params?.limit ?? 50));
  if (params?.siteId) search.set('siteId', params.siteId);
  if (params?.status && params.status !== 'ALL') search.set('status', params.status);
  const queryText = (params?.search ?? params?.q)?.trim();
  if (queryText) search.set('search', queryText);
  if (params?.sort) search.set('sort', params.sort);
  if (params?.dir) search.set('dir', params.dir);
  if (params?.duplicatesOnly) search.set('duplicatesOnly', 'true');

  const response = await serverAuthenticatedFetch<AdminReportListResponse>(`/reports?${search.toString()}`, {
    method: 'GET',
  });

  return {
    data: response.data.map(mapAdminReportListItem),
    meta: response.meta,
  };
}

/** @deprecated Prefer getReportsPage for paginated lists. */
export async function getReports(params?: { siteId?: string }): Promise<ReportRow[]> {
  const { data } = await getReportsPage({
    page: 1,
    limit: 100,
    ...(params?.siteId ? { siteId: params.siteId } : {}),
  });
  return data;
}

export async function getReportsQueueSummary(): Promise<ReportsQueueSummary> {
  return serverAuthenticatedFetch<ReportsQueueSummary>('/reports/queue-summary', {
    method: 'GET',
  });
}

export async function getReportDetail(reportId: string): Promise<ReportDetail> {

  const detail = await serverAuthenticatedFetch<ReportDetail & { potentialDuplicateOfReportNumber?: string | null }>(
    `/reports/${reportId}`,
    {
      method: 'GET',
    },
  );

  const { potentialDuplicateOfReportNumber, ...rest } = detail;
  return {
    ...rest,
    ...(potentialDuplicateOfReportNumber != null ? { potentialDuplicateOfReportNumber } : {}),
  };
}

export type DuplicateReportGroupsPage = {
  data: DuplicateReportGroup[];
  meta: { page: number; limit: number; total: number };
};

export async function getDuplicateReportGroups(params?: {
  page?: number;
  limit?: number;
}): Promise<DuplicateReportGroupsPage> {
  const search = new URLSearchParams();
  search.set('page', String(params?.page ?? 1));
  search.set('limit', String(params?.limit ?? 20));

  const response = await serverAuthenticatedFetch<DuplicateReportGroupsResponse>(
    `/reports/duplicates?${search.toString()}`,
    {
      method: 'GET',
    },
  );

  return {
    data: response.data,
    meta: response.meta,
  };
}

export async function getDuplicateReportGroup(reportId: string): Promise<DuplicateReportGroup> {
  return serverAuthenticatedFetch<DuplicateReportGroup>(`/reports/${reportId}/duplicates`, {
    method: 'GET',
  });
}
