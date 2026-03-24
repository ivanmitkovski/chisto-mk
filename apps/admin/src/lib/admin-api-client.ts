/**
 * Client-side API functions for React Query.
 * Uses adminBrowserFetch (requires browser, auth token from cookie).
 */
import type { IconName } from '@/components/ui';
import { adminBrowserFetch } from './admin-browser-api';

export const adminQueryKeys = {
  overview: ['admin', 'overview'] as const,
  stats: ['admin', 'stats'] as const,
  reports: (filters?: { siteId?: string }) => ['admin', 'reports', filters ?? {}] as const,
  reportsAll: ['admin', 'reports'] as const,
  users: (params?: { page?: number; limit?: number; search?: string; role?: string; status?: string }) =>
    ['admin', 'users', params ?? {}] as const,
  usersAll: ['admin', 'users'] as const,
  usersStats: ['admin', 'users', 'stats'] as const,
  sites: (params?: { page?: number; limit?: number; status?: string }) =>
    ['admin', 'sites', params ?? {}] as const,
  sitesAll: ['admin', 'sites'] as const,
  sitesStats: ['admin', 'sites', 'stats'] as const,
  notifications: ['admin', 'notifications'] as const,
};

type AdminOverviewResponse = {
  reportsByStatus: Record<string, number>;
  sitesByStatus: Record<string, number>;
  duplicateGroupsCount?: number;
  cleanupEvents: {
    upcoming: number;
    completed: number;
    pending?: number;
    upcomingEvents?: Array<{ id: string; name: string; date: string }>;
  };
  usersCount: number;
  usersNewLast7d: number;
  sessionsActive: number;
  reportsTrend: Array<{ date: string; count: number }>;
  recentActivity: Array<{
    id: string;
    type: string;
    title: string;
    subline?: string;
    occurredAt: string;
  }>;
};

export type DashboardOverview = {
  stats: Array<{
    id: string;
    label: string;
    value: number;
    tone: string;
    icon: string;
    href?: string;
    group: string;
    trend?: 'up' | 'neutral';
    trendLabel?: string | undefined;
  }>;
  reportsTrend: Array<{ date: string; count: number }>;
  recentActivity: AdminOverviewResponse['recentActivity'];
  cleanupEvents: AdminOverviewResponse['cleanupEvents'] & {
    upcomingEvents: Array<{ id: string; name: string; date: string }>;
  };
};

export async function fetchDashboardOverview(): Promise<DashboardOverview> {
  const overview = await adminBrowserFetch<AdminOverviewResponse>('/admin/overview');
  const sitesTotal = Object.values(overview.sitesByStatus ?? {}).reduce((sum, n) => sum + n, 0);
  const duplicateCount = overview.duplicateGroupsCount ?? 0;
  const stats = [
    {
      id: 'new',
      label: 'New Reports',
      value: overview.reportsByStatus?.['NEW'] ?? 0,
      tone: 'mint',
      icon: 'document-text',
      href: '/dashboard/reports?status=NEW',
      group: 'reports',
    },
    {
      id: 'in-review',
      label: 'In Review',
      value: overview.reportsByStatus?.['IN_REVIEW'] ?? 0,
      tone: 'mint',
      icon: 'document-forward',
      href: '/dashboard/reports?status=IN_REVIEW',
      group: 'reports',
    },
    {
      id: 'approved',
      label: 'Approved',
      value: overview.reportsByStatus?.['APPROVED'] ?? 0,
      tone: 'green',
      icon: 'document-forward',
      href: '/dashboard/reports?status=APPROVED',
      group: 'reports',
    },
    {
      id: 'deleted',
      label: 'Deleted',
      value: overview.reportsByStatus?.['DELETED'] ?? 0,
      tone: 'red',
      icon: 'clipboard-close',
      href: '/dashboard/reports?status=DELETED',
      group: 'reports',
    },
    ...(duplicateCount > 0
      ? [
          {
            id: 'duplicates',
            label: 'Duplicate groups',
            value: duplicateCount,
            tone: 'yellow',
            icon: 'document-duplicate',
            href: '/dashboard/reports/duplicates',
            group: 'reports',
          },
        ]
      : []),
    {
      id: 'users',
      label: 'Users',
      value: overview.usersCount ?? 0,
      tone: 'mint',
      icon: 'users',
      href: '/dashboard/users',
      group: 'platform',
      ...((overview.usersNewLast7d ?? 0) > 0
        ? { trend: 'up' as const, trendLabel: `+${overview.usersNewLast7d} last 7d` }
        : {}),
    },
    {
      id: 'sessions-active',
      label: 'Active Sessions',
      value: overview.sessionsActive ?? 0,
      tone: 'green',
      icon: 'shield',
      group: 'platform',
    },
    {
      id: 'sites',
      label: 'Sites',
      value: sitesTotal,
      tone: 'mint',
      icon: 'location',
      href: '/dashboard/sites',
      group: 'platform',
    },
    {
      id: 'cleanup-upcoming',
      label: 'Upcoming',
      value: overview.cleanupEvents?.upcoming ?? 0,
      tone: 'green',
      icon: 'calendar',
      href: '/dashboard/events',
      group: 'cleanups',
    },
    {
      id: 'cleanup-completed',
      label: 'Completed',
      value: overview.cleanupEvents?.completed ?? 0,
      tone: 'green',
      icon: 'check',
      href: '/dashboard/events',
      group: 'cleanups',
    },
  ];
  return {
    stats,
    reportsTrend: overview.reportsTrend ?? [],
    recentActivity: overview.recentActivity ?? [],
    cleanupEvents: {
      ...overview.cleanupEvents,
      upcomingEvents: overview.cleanupEvents?.upcomingEvents ?? [],
    },
  };
}

type ReportRow = {
  id: string;
  reportNumber: string;
  name: string;
  location: string;
  dateReportedAt: string;
  status: string;
  isPotentialDuplicate: boolean;
  coReporterCount: number;
};

type ReportsListResponse = {
  data: ReportRow[];
  meta: { page: number; limit: number; total: number };
};

export async function fetchReports(params?: { siteId?: string }): Promise<ReportRow[]> {
  const search = new URLSearchParams();
  if (params?.siteId) search.set('siteId', params.siteId);
  const suffix = search.size > 0 ? `?${search.toString()}` : '';
  const response = await adminBrowserFetch<ReportsListResponse>(`/reports${suffix}`);
  return response.data;
}

type AdminNotificationApiItem = {
  id: string;
  title: string;
  message: string;
  timeLabel: string;
  tone: string;
  category: string;
  isUnread: boolean;
  href: string | null;
};

function toneCategoryToIcon(tone: string, category: string): IconName {
  if (category === 'reports') return 'document-text';
  if (category === 'system') return 'shield';
  if (category === 'analytics') return 'document-duplicate';
  if (tone === 'warning') return 'alert-triangle';
  if (tone === 'success') return 'check';
  return 'info';
}

export type AdminNotificationItem = {
  id: string;
  title: string;
  message: string;
  timeLabel: string;
  tone: string;
  isUnread: boolean;
  category: string;
  icon: IconName;
  href?: string;
};

export async function fetchNotifications(): Promise<{
  items: AdminNotificationItem[];
  unreadCount: number;
}> {
  const response = await adminBrowserFetch<{
    data: AdminNotificationApiItem[];
    meta: { unreadCount: number };
  }>('/admin/notifications');
  return {
    items: response.data.map((item) => ({
      id: item.id,
      title: item.title,
      message: item.message,
      timeLabel: item.timeLabel,
      tone: item.tone,
      isUnread: item.isUnread,
      category: item.category,
      icon: toneCategoryToIcon(item.tone, item.category),
      ...(item.href && { href: item.href }),
    })),
    unreadCount: response.meta.unreadCount,
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

export async function fetchUsers(params?: {
  page?: number;
  limit?: number;
  search?: string;
  role?: string;
  status?: string;
}): Promise<{ data: UserRow[]; meta: { page: number; limit: number; total: number } }> {
  const search = new URLSearchParams();
  if (params?.page) search.set('page', String(params.page));
  if (params?.limit) search.set('limit', String(params.limit));
  if (params?.search) search.set('search', params.search);
  if (params?.role) search.set('role', params.role);
  if (params?.status) search.set('status', params.status);
  const q = search.size > 0 ? `?${search.toString()}` : '';
  return adminBrowserFetch(`/admin/users${q}`);
}

export async function fetchUsersStats(): Promise<{
  usersCount: number;
  usersNewLast7d: number;
  sessionsActive: number;
}> {
  const overview = await adminBrowserFetch<{
    usersCount: number;
    usersNewLast7d: number;
    sessionsActive: number;
  }>('/admin/overview');
  return {
    usersCount: overview.usersCount ?? 0,
    usersNewLast7d: overview.usersNewLast7d ?? 0,
    sessionsActive: overview.sessionsActive ?? 0,
  };
}

export type SiteRow = {
  id: string;
  latitude: number;
  longitude: number;
  description: string | null;
  status: string;
  createdAt: string;
  reportCount: number;
};

export async function fetchSitesList(params?: {
  page?: number;
  limit?: number;
  status?: string;
}): Promise<{
  data: SiteRow[];
  meta: { page: number; limit: number; total: number };
}> {
  const page = params?.page ?? 1;
  const limit = params?.limit ?? 20;
  const search = new URLSearchParams({ page: String(page), limit: String(limit) });
  if (params?.status) search.set('status', params.status);
  return adminBrowserFetch(`/sites?${search.toString()}`);
}

export async function fetchSitesStats(): Promise<{
  total: number;
  byStatus: Record<string, number>;
}> {
  const overview = await adminBrowserFetch<{ sitesByStatus: Record<string, number> }>(
    '/admin/overview',
  );
  const byStatus = overview.sitesByStatus ?? {};
  const total = Object.values(byStatus).reduce((sum, n) => sum + n, 0);
  return { total, byStatus };
}
