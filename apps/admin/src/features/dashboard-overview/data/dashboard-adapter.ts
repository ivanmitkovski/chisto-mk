import { getTranslations } from 'next-intl/server';
import { serverAuthenticatedFetch } from '@/lib/auth/server-api-with-refresh';
import type { Schema } from '@/lib/api';
import type { RecentActivityItem, ReportsTrendItem, StatCard } from '../types';

type AdminOverviewResponse = Schema<'AdminOverviewResponseDto'>;

function normalizeRecentActivity(
  items: AdminOverviewResponse['recentActivity'] | undefined,
): RecentActivityItem[] {
  return (items ?? []).map((item) => ({
    id: item.id,
    createdAt: item.createdAt,
    action: item.action,
    resourceType: item.resourceType,
    resourceId: typeof item.resourceId === 'string' ? item.resourceId : null,
    actorEmail: typeof item.actorEmail === 'string' ? item.actorEmail : null,
  }));
}

export async function getDashboardStats(): Promise<StatCard[]> {
  const t = await getTranslations('dashboard');
  const overview = await serverAuthenticatedFetch<AdminOverviewResponse>('/admin/overview', {
    method: 'GET',
  });

  const sitesTotal = Object.values(overview.sitesByStatus).reduce((sum, n) => sum + n, 0);

  return [
    { id: 'new', label: t('stats.newReports'), value: overview.reportsByStatus['NEW'] ?? 0, tone: 'yellow', icon: 'document-text', group: 'reports' as const, highlight: true },
    { id: 'in-review', label: t('stats.inReview'), value: overview.reportsByStatus['IN_REVIEW'] ?? 0, tone: 'mint', icon: 'document-forward', group: 'reports' as const, highlight: true },
    { id: 'approved', label: t('stats.approved'), value: overview.reportsByStatus['APPROVED'] ?? 0, tone: 'green', icon: 'document-forward', group: 'reports' as const },
    { id: 'deleted', label: t('stats.deleted'), value: overview.reportsByStatus['DELETED'] ?? 0, tone: 'red', icon: 'clipboard-close', group: 'reports' as const },
    {
      id: 'users',
      label: t('stats.users'),
      value: overview.usersCount,
      tone: 'mint',
      icon: 'users',
      group: 'platform' as const,
      ...(overview.usersNewLast7d > 0
        ? { trend: 'up' as const, trendLabel: t('stats.usersTrend', { count: overview.usersNewLast7d }) }
        : { trend: 'neutral' as const }),
    },
    { id: 'sessions-active', label: t('stats.activeSessions'), value: overview.sessionsActive, tone: 'green', icon: 'shield', group: 'platform' as const },
    { id: 'sites', label: t('stats.sites'), value: sitesTotal, tone: 'mint', icon: 'location', group: 'platform' as const },
    { id: 'cleanup-upcoming', label: t('stats.upcoming'), value: overview.cleanupEvents.upcoming, tone: 'green', icon: 'calendar', group: 'cleanups' as const },
    { id: 'cleanup-completed', label: t('stats.completed'), value: overview.cleanupEvents.completed, tone: 'green', icon: 'check', group: 'cleanups' as const },
  ];
}

export async function getDashboardOverview(): Promise<{
  stats: StatCard[];
  reportsTrend: ReportsTrendItem[];
  recentActivity: RecentActivityItem[];
  cleanupEvents: { upcoming: number; completed: number; pending?: number; upcomingEvents: Array<{ id: string; name: string; date: string }> };
  feedDiagnostics: {
    reasonCodes: Array<{ code: string; count: number }>;
    rankDriftSnapshot: Array<{ siteId: string; score: number; reasons: string[] }>;
    recentIntegrityDemotions: number;
  };
}> {
  const t = await getTranslations('dashboard');
  const overview = await serverAuthenticatedFetch<AdminOverviewResponse>('/admin/overview', {
    method: 'GET',
  });
  const sitesTotal = Object.values(overview.sitesByStatus).reduce((sum, n) => sum + n, 0);
  const duplicateCount = overview.duplicateGroupsCount ?? 0;
  const stats: StatCard[] = [
    { id: 'new', label: t('stats.newReports'), value: overview.reportsByStatus['NEW'] ?? 0, tone: 'mint', icon: 'document-text', href: '/dashboard/reports?status=NEW', group: 'reports' as const },
    { id: 'in-review', label: t('stats.inReview'), value: overview.reportsByStatus['IN_REVIEW'] ?? 0, tone: 'mint', icon: 'document-forward', href: '/dashboard/reports?status=IN_REVIEW', group: 'reports' as const },
    { id: 'approved', label: t('stats.approved'), value: overview.reportsByStatus['APPROVED'] ?? 0, tone: 'green', icon: 'document-forward', href: '/dashboard/reports?status=APPROVED', group: 'reports' as const },
    { id: 'deleted', label: t('stats.deleted'), value: overview.reportsByStatus['DELETED'] ?? 0, tone: 'red', icon: 'clipboard-close', href: '/dashboard/reports?status=DELETED', group: 'reports' as const },
    ...(duplicateCount > 0 ? [{ id: 'duplicates', label: t('stats.duplicateGroups'), value: duplicateCount, tone: 'yellow' as const, icon: 'document-duplicate' as const, href: '/dashboard/reports/duplicates', group: 'reports' as const }] : []),
    {
      id: 'users',
      label: t('stats.users'),
      value: overview.usersCount,
      tone: 'mint',
      icon: 'users',
      href: '/dashboard/users',
      group: 'platform' as const,
      ...(overview.usersNewLast7d > 0
        ? { trend: 'up' as const, trendLabel: t('stats.usersTrend', { count: overview.usersNewLast7d }) }
        : { trend: 'neutral' as const }),
    },
    { id: 'sessions-active', label: t('stats.activeSessions'), value: overview.sessionsActive, tone: 'green', icon: 'shield', group: 'platform' as const },
    { id: 'sites', label: t('stats.sites'), value: sitesTotal, tone: 'mint', icon: 'location', href: '/dashboard/sites', group: 'platform' as const },
    { id: 'cleanup-upcoming', label: t('stats.upcoming'), value: overview.cleanupEvents.upcoming, tone: 'green', icon: 'calendar', href: '/dashboard/events', group: 'cleanups' as const },
    { id: 'cleanup-completed', label: t('stats.completed'), value: overview.cleanupEvents.completed, tone: 'green', icon: 'check', href: '/dashboard/events', group: 'cleanups' as const },
  ];
  return {
    stats,
    reportsTrend: overview.reportsTrend ?? [],
    recentActivity: normalizeRecentActivity(overview.recentActivity),
    cleanupEvents: {
      ...overview.cleanupEvents,
      upcomingEvents: overview.cleanupEvents.upcomingEvents ?? [],
    },
    feedDiagnostics: {
      reasonCodes: overview.feedDiagnostics?.reasonCodes ?? [],
      rankDriftSnapshot: overview.feedDiagnostics?.rankDriftSnapshot ?? [],
      recentIntegrityDemotions: overview.feedDiagnostics?.recentIntegrityDemotions ?? 0,
    },
  };
}

export type DashboardOverview = Awaited<ReturnType<typeof getDashboardOverview>>;
