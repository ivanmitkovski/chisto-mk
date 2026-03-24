import { apiFetch } from '@/lib/api';
import { getAdminAuthTokenFromCookies } from '@/features/auth/lib/admin-auth-server';
import type { RecentActivityItem, ReportsTrendItem, StatCard } from '../../types';

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
  recentActivity: RecentActivityItem[];
};

export async function getDashboardStats(): Promise<StatCard[]> {
  const token = await getAdminAuthTokenFromCookies();

  const overview = await apiFetch<AdminOverviewResponse>('/admin/overview', {
    method: 'GET',
    authToken: token,
  });

  const sitesTotal = Object.values(overview.sitesByStatus).reduce((sum, n) => sum + n, 0);

  return [
    { id: 'new', label: 'New Reports', value: overview.reportsByStatus['NEW'] ?? 0, tone: 'yellow', icon: 'document-text', group: 'reports' as const, highlight: true },
    { id: 'in-review', label: 'In Review', value: overview.reportsByStatus['IN_REVIEW'] ?? 0, tone: 'mint', icon: 'document-forward', group: 'reports' as const, highlight: true },
    { id: 'approved', label: 'Approved Reports', value: overview.reportsByStatus['APPROVED'] ?? 0, tone: 'green', icon: 'document-forward', group: 'reports' as const },
    { id: 'deleted', label: 'Deleted Reports', value: overview.reportsByStatus['DELETED'] ?? 0, tone: 'red', icon: 'clipboard-close', group: 'reports' as const },
    {
      id: 'users',
      label: 'Users',
      value: overview.usersCount,
      tone: 'mint',
      icon: 'users',
      group: 'platform' as const,
      ...(overview.usersNewLast7d > 0
        ? { trend: 'up' as const, trendLabel: `+${overview.usersNewLast7d} last 7d` }
        : { trend: 'neutral' as const }),
    },
    { id: 'sessions-active', label: 'Active Sessions', value: overview.sessionsActive, tone: 'green', icon: 'shield', group: 'platform' as const },
    { id: 'sites', label: 'Sites', value: sitesTotal, tone: 'mint', icon: 'location', group: 'platform' as const },
    { id: 'cleanup-upcoming', label: 'Upcoming Cleanups', value: overview.cleanupEvents.upcoming, tone: 'green', icon: 'calendar', group: 'cleanups' as const },
    { id: 'cleanup-completed', label: 'Completed Cleanups', value: overview.cleanupEvents.completed, tone: 'green', icon: 'check', group: 'cleanups' as const },
  ];
}

export async function getDashboardOverview(): Promise<{
  stats: StatCard[];
  reportsTrend: ReportsTrendItem[];
  recentActivity: RecentActivityItem[];
  cleanupEvents: { upcoming: number; completed: number; pending?: number; upcomingEvents: Array<{ id: string; name: string; date: string }> };
}> {
  const token = await getAdminAuthTokenFromCookies();
  const overview = await apiFetch<AdminOverviewResponse>('/admin/overview', {
    method: 'GET',
    authToken: token,
  });
  const sitesTotal = Object.values(overview.sitesByStatus).reduce((sum, n) => sum + n, 0);
  const duplicateCount = overview.duplicateGroupsCount ?? 0;
  const stats: StatCard[] = [
    { id: 'new', label: 'New Reports', value: overview.reportsByStatus['NEW'] ?? 0, tone: 'mint', icon: 'document-text', href: '/dashboard/reports?status=NEW', group: 'reports' as const },
    { id: 'in-review', label: 'In Review', value: overview.reportsByStatus['IN_REVIEW'] ?? 0, tone: 'mint', icon: 'document-forward', href: '/dashboard/reports?status=IN_REVIEW', group: 'reports' as const },
    { id: 'approved', label: 'Approved', value: overview.reportsByStatus['APPROVED'] ?? 0, tone: 'green', icon: 'document-forward', href: '/dashboard/reports?status=APPROVED', group: 'reports' as const },
    { id: 'deleted', label: 'Deleted', value: overview.reportsByStatus['DELETED'] ?? 0, tone: 'red', icon: 'clipboard-close', href: '/dashboard/reports?status=DELETED', group: 'reports' as const },
    ...(duplicateCount > 0 ? [{ id: 'duplicates', label: 'Duplicate groups', value: duplicateCount, tone: 'yellow' as const, icon: 'document-duplicate' as const, href: '/dashboard/reports/duplicates', group: 'reports' as const }] : []),
    {
      id: 'users',
      label: 'Users',
      value: overview.usersCount,
      tone: 'mint',
      icon: 'users',
      href: '/dashboard/users',
      group: 'platform' as const,
      ...(overview.usersNewLast7d > 0
        ? { trend: 'up' as const, trendLabel: `+${overview.usersNewLast7d} last 7d` }
        : { trend: 'neutral' as const }),
    },
    { id: 'sessions-active', label: 'Active Sessions', value: overview.sessionsActive, tone: 'green', icon: 'shield', group: 'platform' as const },
    { id: 'sites', label: 'Sites', value: sitesTotal, tone: 'mint', icon: 'location', href: '/dashboard/sites', group: 'platform' as const },
    { id: 'cleanup-upcoming', label: 'Upcoming', value: overview.cleanupEvents.upcoming, tone: 'green', icon: 'calendar', href: '/dashboard/events', group: 'cleanups' as const },
    { id: 'cleanup-completed', label: 'Completed', value: overview.cleanupEvents.completed, tone: 'green', icon: 'check', href: '/dashboard/events', group: 'cleanups' as const },
  ];
  return {
    stats,
    reportsTrend: overview.reportsTrend ?? [],
    recentActivity: overview.recentActivity ?? [],
    cleanupEvents: {
      ...overview.cleanupEvents,
      upcomingEvents: overview.cleanupEvents.upcomingEvents ?? [],
    },
  };
}

export type DashboardOverview = Awaited<ReturnType<typeof getDashboardOverview>>;
