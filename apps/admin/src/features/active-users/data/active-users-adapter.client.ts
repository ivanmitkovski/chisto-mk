import { adminBrowserFetch } from '@/lib/api';
import type {
  ActiveUserRow,
  ActiveUsersSummary,
  ActivityFeedItem,
  AdminAlertRule,
  RealtimeAnalytics,
} from './active-users.types';

export type ActiveUsersListFilters = {
  page?: number;
  limit?: number;
  status?: string;
  platform?: string;
  search?: string;
};

export function buildActiveUsersListQuery(filters: ActiveUsersListFilters): string {
  const params = new URLSearchParams();
  params.set('page', String(filters.page ?? 1));
  params.set('limit', String(filters.limit ?? 25));
  if (filters.status) params.set('status', filters.status);
  if (filters.platform) params.set('platform', filters.platform);
  if (filters.search?.trim()) params.set('search', filters.search.trim());
  return params.toString();
}

export function browserFetchSummary() {
  return adminBrowserFetch<ActiveUsersSummary>('/admin/active-users/summary');
}

export function browserFetchRealtime() {
  return adminBrowserFetch<RealtimeAnalytics>('/admin/analytics/realtime');
}

export function browserFetchActiveUsersList(filters: ActiveUsersListFilters) {
  return adminBrowserFetch<{ rows: ActiveUserRow[]; total: number }>(
    `/admin/active-users?${buildActiveUsersListQuery(filters)}`,
  );
}

export function browserFetchActivityFeed(page = 1, limit = 50, type?: string) {
  const params = new URLSearchParams({ page: String(page), limit: String(limit) });
  if (type) params.set('type', type);
  return adminBrowserFetch<{ items: ActivityFeedItem[]; total: number }>(
    `/admin/active-users/activity-feed?${params.toString()}`,
  );
}

export type CreateAlertRulePayload = {
  metric: string;
  threshold: number;
  windowSeconds?: number;
  comparator?: 'GT' | 'GTE';
};

export function browserCreateAlertRule(payload: CreateAlertRulePayload) {
  return adminBrowserFetch<AdminAlertRule>('/admin/alert-rules', {
    method: 'POST',
    body: payload,
  });
}

export function browserUpdateAlertRule(
  id: string,
  payload: { threshold?: number; enabled?: boolean },
) {
  return adminBrowserFetch<AdminAlertRule>(`/admin/alert-rules/${encodeURIComponent(id)}`, {
    method: 'PATCH',
    body: payload,
  });
}

export function browserDeleteAlertRule(id: string) {
  return adminBrowserFetch<{ ok: true }>(`/admin/alert-rules/${encodeURIComponent(id)}`, {
    method: 'DELETE',
  });
}
