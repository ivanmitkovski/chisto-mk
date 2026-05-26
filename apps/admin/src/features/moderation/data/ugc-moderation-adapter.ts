import { getAdminAuthTokenFromCookies } from '@/features/auth/lib/admin-auth-server';
import { apiFetch } from '@/lib/api';

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
  createdAt: string;
  updatedAt: string;
};

export type UgcModerationListResponse = {
  data: UgcModerationReport[];
  meta: { page: number; limit: number; total: number };
};

export async function getUgcModerationReports(params: {
  status?: string;
  subjectType?: string;
  search?: string;
} = {}): Promise<UgcModerationListResponse> {
  const token = await getAdminAuthTokenFromCookies();
  const search = new URLSearchParams({ page: '1', limit: '50' });
  if (params.status) search.set('status', params.status);
  if (params.subjectType) search.set('subjectType', params.subjectType);
  if (params.search) search.set('search', params.search);
  return apiFetch<UgcModerationListResponse>(`/admin/moderation/ugc-reports?${search.toString()}`, {
    method: 'GET',
    authToken: token,
  });
}
