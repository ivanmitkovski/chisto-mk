import { adminBrowserFetch } from '@/lib/api';
import type { ActiveUsersSummary, ActivityFeedItem, RealtimeAnalytics } from './active-users.types';

export function browserFetchSummary() {
  return adminBrowserFetch<ActiveUsersSummary>('/admin/active-users/summary');
}

export function browserFetchRealtime() {
  return adminBrowserFetch<RealtimeAnalytics>('/admin/analytics/realtime');
}

export function browserFetchActivityFeed(page = 1, limit = 50) {
  return adminBrowserFetch<{ items: ActivityFeedItem[]; total: number }>(
    `/admin/active-users/activity-feed?page=${page}&limit=${limit}`,
  );
}
