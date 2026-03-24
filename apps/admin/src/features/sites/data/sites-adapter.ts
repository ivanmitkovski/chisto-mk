import { apiFetch } from '@/lib/api';
import { getAdminAuthTokenFromCookies } from '@/features/auth/lib/admin-auth-server';

export type SiteRow = {
  id: string;
  latitude: number;
  longitude: number;
  description: string | null;
  status: string;
  createdAt: string;
  reportCount: number;
};

export type SitesStats = {
  total: number;
  byStatus: Record<string, number>;
};

type ListResponse = {
  data: SiteRow[];
  meta: { page: number; limit: number; total: number };
};

export async function getSitesStats(): Promise<SitesStats> {
  const token = await getAdminAuthTokenFromCookies();
  const overview = await apiFetch<{ sitesByStatus: Record<string, number> }>('/admin/overview', {
    method: 'GET',
    authToken: token,
  });
  const byStatus = overview.sitesByStatus ?? {};
  const total = Object.values(byStatus).reduce((sum, n) => sum + n, 0);
  return { total, byStatus };
}

export async function getSitesList(params?: {
  page?: number;
  limit?: number;
  status?: string;
}): Promise<ListResponse> {
  const token = await getAdminAuthTokenFromCookies();
  const page = params?.page ?? 1;
  const limit = params?.limit ?? 20;
  const search = new URLSearchParams({
    page: String(page),
    limit: String(limit),
  });
  if (params?.status) {
    search.set('status', params.status);
  }
  return apiFetch<ListResponse>(`/sites?${search.toString()}`, {
    method: 'GET',
    authToken: token,
  });
}

export async function getSiteDetail(id: string) {
  const token = await getAdminAuthTokenFromCookies();
  return apiFetch(`/sites/${id}`, {
    method: 'GET',
    authToken: token,
  });
}
