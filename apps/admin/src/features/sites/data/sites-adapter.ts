import { serverAuthenticatedFetch } from '@/lib/auth/server-api-with-refresh';

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
  const overview = await serverAuthenticatedFetch<{ sitesByStatus: Record<string, number> }>('/admin/overview', {
    method: 'GET',
  });
  const byStatus = overview.sitesByStatus ?? {};
  const total = Object.values(byStatus).reduce((sum, n) => sum + n, 0);
  return { total, byStatus };
}

export async function getSitesList(params?: {
  page?: number;
  limit?: number;
  status?: string;
  search?: string;
}): Promise<ListResponse> {
  const page = params?.page ?? 1;
  const limit = params?.limit ?? 20;
  const search = new URLSearchParams({
    page: String(page),
    limit: String(limit),
  });
  if (params?.status) {
    search.set('status', params.status);
  }
  if (params?.search?.trim()) {
    search.set('search', params.search.trim());
  }
  return serverAuthenticatedFetch<ListResponse>(`/sites/admin/list?${search.toString()}`, {
    method: 'GET',
  });
}

export async function getSiteDetail(id: string) {
  return serverAuthenticatedFetch(`/sites/${id}`, {
    method: 'GET',
  });
}
