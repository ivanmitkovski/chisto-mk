import 'server-only';

import { serverAuthenticatedFetch } from '@/lib/auth/server-api-with-refresh';
import type {
  ActiveUsersSummary,
  ActiveUserRow,
  ActivityFeedItem,
  AdminAlertRule,
  EngagementAnalytics,
  GeoCluster,
  RealtimeAnalytics,
} from './active-users.types';

export async function fetchActiveUsersSummary(): Promise<ActiveUsersSummary> {
  return serverAuthenticatedFetch<ActiveUsersSummary>('/admin/active-users/summary');
}

export async function fetchActiveUsersList(params: URLSearchParams) {
  return serverAuthenticatedFetch<{ rows: ActiveUserRow[]; total: number }>(
    `/admin/active-users?${params.toString()}`,
  );
}

export async function fetchActivityFeed(params: URLSearchParams) {
  return serverAuthenticatedFetch<{ items: ActivityFeedItem[]; total: number }>(
    `/admin/active-users/activity-feed?${params.toString()}`,
  );
}

export async function fetchEngagementAnalytics(): Promise<EngagementAnalytics> {
  return serverAuthenticatedFetch<EngagementAnalytics>('/admin/analytics/engagement');
}

export async function fetchRealtimeAnalytics(): Promise<RealtimeAnalytics> {
  return serverAuthenticatedFetch<RealtimeAnalytics>('/admin/analytics/realtime');
}

export async function fetchGeoClusters(): Promise<GeoCluster[]> {
  return serverAuthenticatedFetch<GeoCluster[]>('/admin/active-users/geo');
}

export async function fetchUserDetails(userId: string) {
  return serverAuthenticatedFetch(`/admin/active-users/${userId}`);
}

export async function fetchAlertRules(): Promise<AdminAlertRule[]> {
  return serverAuthenticatedFetch<AdminAlertRule[]>('/admin/alert-rules');
}
