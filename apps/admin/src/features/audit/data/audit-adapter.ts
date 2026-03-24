import { apiFetch } from '@/lib/api';
import { getAdminAuthTokenFromCookies } from '@/features/auth/lib/admin-auth-server';

export type AuditRow = {
  id: string;
  createdAt: string;
  action: string;
  resourceType: string;
  resourceId: string | null;
  actorEmail: string | null;
  metadata: unknown;
};

type ListResponse = {
  data: AuditRow[];
  meta: { page: number; limit: number; total: number };
};

export async function getAuditLog(
  page = 1,
  limit = 20,
  params?: {
    action?: string;
    resourceType?: string;
    resourceId?: string;
    actorId?: string;
    from?: string;
    to?: string;
  },
): Promise<ListResponse> {
  const token = await getAdminAuthTokenFromCookies();
  const search = new URLSearchParams({ page: String(page), limit: String(limit) });
  if (params?.action) search.set('action', params.action);
  if (params?.resourceType) search.set('resourceType', params.resourceType);
  if (params?.resourceId) search.set('resourceId', params.resourceId);
  if (params?.actorId) search.set('actorId', params.actorId);
  if (params?.from) search.set('from', params.from);
  if (params?.to) search.set('to', params.to);
  return apiFetch<ListResponse>(`/admin/audit?${search.toString()}`, {
    method: 'GET',
    authToken: token,
  });
}
