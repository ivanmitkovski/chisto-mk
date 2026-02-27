import { apiFetch } from '@/lib/api';
import { getAdminAuthTokenFromCookies } from '@/features/auth/lib/admin-auth-server';
import { ReportDetail, ReportRow } from '../../types';

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

  const detail = await apiFetch<ReportDetail>(`/reports/${reportId}`, {
    method: 'GET',
    authToken: token,
  });

  return detail;
}
