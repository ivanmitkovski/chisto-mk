import { apiFetch } from '@/lib/api';
import { getAdminAuthTokenFromCookies } from '@/features/auth/lib/admin-auth-server';
import { DuplicateReportGroup, ReportDetail, ReportRow } from '../../types';

type AdminReportListItem = {
  id: string;
  reportNumber: string;
  name: string;
  location: string;
  dateReportedAt: string;
  status: ReportRow['status'];
  isPotentialDuplicate: boolean;
  coReporterCount: number;
  cleanupEffortLabel: string | null;
};

type AdminReportListResponse = {
  data: AdminReportListItem[];
  meta: {
    page: number;
    limit: number;
    total: number;
  };
};

type DuplicateReportGroupsResponse = {
  data: DuplicateReportGroup[];
  meta: {
    page: number;
    limit: number;
    total: number;
  };
};

const ADMIN_REPORTS_PAGE_LIMIT = 100;
/** Safety cap: 25 pages × 100 = 2500 rows before stopping even if meta is wrong. */
const ADMIN_REPORTS_MAX_PAGES = 25;

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
    cleanupEffortLabel: item.cleanupEffortLabel,
  };
}

export async function getReports(params?: { siteId?: string }): Promise<ReportRow[]> {
  const token = await getAdminAuthTokenFromCookies();
  const base = new URLSearchParams();
  if (params?.siteId) {
    base.set('siteId', params.siteId);
  }

  const aggregated: ReportRow[] = [];
  for (let page = 1; page <= ADMIN_REPORTS_MAX_PAGES; page += 1) {
    const search = new URLSearchParams(base);
    search.set('page', String(page));
    search.set('limit', String(ADMIN_REPORTS_PAGE_LIMIT));

    const response = await apiFetch<AdminReportListResponse>(`/reports?${search.toString()}`, {
      method: 'GET',
      authToken: token,
    });

    aggregated.push(...response.data.map(mapAdminReportListItem));

    const total = response.meta?.total ?? aggregated.length;
    const pageSize = response.data.length;
    if (aggregated.length >= total || pageSize < ADMIN_REPORTS_PAGE_LIMIT) {
      break;
    }
  }

  return aggregated;
}

export async function getReportDetail(reportId: string): Promise<ReportDetail> {
  const token = await getAdminAuthTokenFromCookies();

  const detail = await apiFetch<ReportDetail & { potentialDuplicateOfReportNumber?: string | null }>(
    `/reports/${reportId}`,
    {
      method: 'GET',
      authToken: token,
    },
  );

  const { potentialDuplicateOfReportNumber, ...rest } = detail;
  return {
    ...rest,
    ...(potentialDuplicateOfReportNumber != null ? { potentialDuplicateOfReportNumber } : {}),
  };
}

export async function getDuplicateReportGroups(params?: { page?: number; limit?: number }): Promise<DuplicateReportGroup[]> {
  const token = await getAdminAuthTokenFromCookies();
  const search = new URLSearchParams();
  if (params?.page) {
    search.set('page', String(params.page));
  }
  if (params?.limit) {
    search.set('limit', String(params.limit));
  }

  const suffix = search.size > 0 ? `?${search.toString()}` : '';
  const response = await apiFetch<DuplicateReportGroupsResponse>(`/reports/duplicates${suffix}`, {
    method: 'GET',
    authToken: token,
  });

  return response.data;
}

export async function getDuplicateReportGroup(reportId: string): Promise<DuplicateReportGroup> {
  const token = await getAdminAuthTokenFromCookies();
  return apiFetch<DuplicateReportGroup>(`/reports/${reportId}/duplicates`, {
    method: 'GET',
    authToken: token,
  });
}
