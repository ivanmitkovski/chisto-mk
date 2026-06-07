import { serverAuthenticatedFetch } from '@/lib/auth/server-api-with-refresh';
import type { Schema } from '@/lib/api';

export type UsersStats = Pick<
  Schema<'AdminOverviewResponseDto'>,
  'usersCount' | 'usersNewLast7d' | 'sessionsActive'
>;

export async function getUsersStats(): Promise<UsersStats> {
  const overview = await serverAuthenticatedFetch<Schema<'AdminOverviewResponseDto'>>('/admin/overview', {
    method: 'GET',
  });
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
  sort?: string;
  dir?: string;
  lastActiveBefore?: string;
  lastActiveAfter?: string;
}): Promise<ListResponse> {
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
  if (params?.sort) {
    search.set('sort', params.sort);
  }
  if (params?.dir) {
    search.set('dir', params.dir);
  }
  if (params?.lastActiveBefore) {
    search.set('lastActiveBefore', params.lastActiveBefore);
  }
  if (params?.lastActiveAfter) {
    search.set('lastActiveAfter', params.lastActiveAfter);
  }
  const q = search.size > 0 ? `?${search.toString()}` : '';
  return serverAuthenticatedFetch<ListResponse>(`/admin/users${q}`, {
    method: 'GET',
  });
}

export async function getUserDetail(id: string) {
  return serverAuthenticatedFetch(`/admin/users/${id}`, {
    method: 'GET',
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
  return serverAuthenticatedFetch(`/admin/users/${id}/audit?page=${page}&limit=${limit}`, {
    method: 'GET',
  });
}

export async function getUserSessions(id: string): Promise<SessionEntry[]> {
  return serverAuthenticatedFetch(`/admin/users/${id}/sessions`, {
    method: 'GET',
  });
}
