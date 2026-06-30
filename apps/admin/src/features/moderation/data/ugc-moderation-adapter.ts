import { serverAuthenticatedFetch } from '@/lib/auth/server-api-with-refresh';

export type UgcModerationReport = {
  id: string;
  reporterId: string;
  reporterName?: string | null;
  reporterEmail?: string | null;
  reporterRole?: string | null;
  reporterStatus?: string | null;
  subjectType: string;
  subjectId: string;
  reason: string;
  details?: string | null;
  status: string;
  caseStatus?: string;
  contentStatus?: string;
  createdAt: string;
  updatedAt: string;
};

export type UgcModerationListResponse = {
  data: UgcModerationReport[];
  meta: { page: number; limit: number; total: number };
};

export async function getUgcModerationReports(params: {
  page?: number;
  limit?: number;
  status?: string;
  subjectType?: string;
  search?: string;
} = {}): Promise<UgcModerationListResponse> {
  const search = new URLSearchParams({
    page: String(params.page ?? 1),
    limit: String(params.limit ?? 50),
  });
  if (params.status) search.set('status', params.status);
  if (params.subjectType) search.set('subjectType', params.subjectType);
  if (params.search) search.set('search', params.search);
  return serverAuthenticatedFetch<UgcModerationListResponse>(`/admin/moderation/ugc-reports?${search.toString()}`, {
    method: 'GET',
  });
}

export async function getUgcModerationReport(reportId: string): Promise<UgcModerationReport> {
  return serverAuthenticatedFetch<UgcModerationReport>(
    `/admin/moderation/ugc-reports/${encodeURIComponent(reportId)}`,
    {
      method: 'GET',
    },
  );
}
