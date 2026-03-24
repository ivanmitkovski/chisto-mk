import { apiFetch } from '@/lib/api';
import { getAdminAuthTokenFromCookies } from '@/features/auth/lib/admin-auth-server';

export type UsersStats = {
  usersCount: number;
  usersNewLast7d: number;
  sessionsActive: number;
};

export async function getUsersStats(): Promise<UsersStats> {
  const token = await getAdminAuthTokenFromCookies();
  const overview = await apiFetch<{ usersCount: number; usersNewLast7d: number; sessionsActive: number }>(
    '/admin/overview',
    { method: 'GET', authToken: token },
  );
  return {
    usersCount: overview.usersCount ?? 0,
    usersNewLast7d: overview.usersNewLast7d ?? 0,
    sessionsActive: overview.sessionsActive ?? 0,
  };
}

export type UserRow = {
  id: string;
  firstName: string;
  lastName: string;
  email: string;
  phoneNumber: string;
  role: string;
  status: string;
  lastActiveAt: string | null;
  pointsBalance: number;
};

type ListResponse = {
  data: UserRow[];
  meta: { page: number; limit: number; total: number };
};

export async function getUsers(params?: {
  page?: number;
  limit?: number;
  search?: string;
  role?: string;
  status?: string;
  lastActiveBefore?: string;
  lastActiveAfter?: string;
}): Promise<ListResponse> {
  const token = await getAdminAuthTokenFromCookies();
  const search = new URLSearchParams();
  if (params?.page) {
    search.set('page', String(params.page));
  }
  if (params?.limit) {
    search.set('limit', String(params.limit));
  }
  if (params?.search) {
    search.set('search', params.search);
  }
  if (params?.role) {
    search.set('role', params.role);
  }
  if (params?.status) {
    search.set('status', params.status);
  }
  if (params?.lastActiveBefore) {
    search.set('lastActiveBefore', params.lastActiveBefore);
  }
  if (params?.lastActiveAfter) {
    search.set('lastActiveAfter', params.lastActiveAfter);
  }
  const q = search.size > 0 ? `?${search.toString()}` : '';
  return apiFetch<ListResponse>(`/admin/users${q}`, {
    method: 'GET',
    authToken: token,
  });
}

export async function getUserDetail(id: string) {
  const token = await getAdminAuthTokenFromCookies();
  return apiFetch(`/admin/users/${id}`, {
    method: 'GET',
    authToken: token,
  });
}

export type AuditEntry = {
  id: string;
  createdAt: string;
  action: string;
  resourceType: string;
  resourceId: string | null;
  actorEmail: string | null;
  metadata: unknown;
};

export type SessionEntry = {
  id: string;
  createdAt: string;
  deviceInfo: string | null;
  ipAddress: string | null;
  expiresAt: string;
  revokedAt: string | null;
};

export async function getUserAudit(
  id: string,
  page = 1,
  limit = 20,
): Promise<{ data: AuditEntry[]; meta: { page: number; limit: number; total: number } }> {
  const token = await getAdminAuthTokenFromCookies();
  return apiFetch(`/admin/users/${id}/audit?page=${page}&limit=${limit}`, {
    method: 'GET',
    authToken: token,
  });
}

export async function getUserSessions(id: string): Promise<SessionEntry[]> {
  const token = await getAdminAuthTokenFromCookies();
  return apiFetch(`/admin/users/${id}/sessions`, {
    method: 'GET',
    authToken: token,
  });
}
