import { serverAuthenticatedFetch } from '@/lib/auth/server-api-with-refresh';

export type SiteResolutionStatus = 'PENDING' | 'APPROVED' | 'REJECTED';

export type SiteResolutionRow = {
  id: string;
  siteId: string;
  siteAddress: string | null;
  status: SiteResolutionStatus;
  mediaUrls: string[];
  note: string | null;
  isReporterSubmission: boolean;
  createdAt: string;
  submitterDisplayLabel: string | null;
  siteStatus: string;
};

export type SiteResolutionListResponse = {
  data: SiteResolutionRow[];
  meta: { page: number; limit: number; total: number };
};

export async function getSiteResolutionsPage(params?: {
  page?: number;
  limit?: number;
  status?: SiteResolutionStatus;
  siteId?: string;
}): Promise<SiteResolutionListResponse> {
  const search = new URLSearchParams({
    page: String(params?.page ?? 1),
    limit: String(params?.limit ?? 50),
  });
  if (params?.status) search.set('status', params.status);
  if (params?.siteId?.trim()) search.set('siteId', params.siteId.trim());

  return serverAuthenticatedFetch<SiteResolutionListResponse>(
    `/sites/admin/resolutions?${search.toString()}`,
    { method: 'GET' },
  );
}

export async function getSiteResolutionsForSite(siteId: string): Promise<SiteResolutionListResponse> {
  return serverAuthenticatedFetch<SiteResolutionListResponse>(
    `/sites/admin/resolutions?siteId=${encodeURIComponent(siteId)}&limit=50`,
    { method: 'GET' },
  );
}
