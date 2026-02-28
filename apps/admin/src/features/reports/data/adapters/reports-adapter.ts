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

export async function getReports(): Promise<ReportRow[]> {
  const token = await getAdminAuthTokenFromCookies();

  const response = await apiFetch<AdminReportListResponse>('/reports', {
    method: 'GET',
    authToken: token,
  });

  return response.data.map((item) => ({
    id: item.id,
    reportNumber: item.reportNumber,
    name: item.name,
    location: item.location,
    dateReportedAt: item.dateReportedAt,
    status: item.status,
    isPotentialDuplicate: item.isPotentialDuplicate,
    coReporterCount: item.coReporterCount,
  }));
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
