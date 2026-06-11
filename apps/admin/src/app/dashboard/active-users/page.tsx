import { cookies } from 'next/headers';
import { getTranslations } from 'next-intl/server';
import { AdminShell, DESKTOP_SIDEBAR_COOKIE_KEY } from '@/features/admin-shell';
import {
  ActiveUsersWorkspace,
  fetchActiveUsersList,
  fetchActiveUsersSummary,
  fetchAlertRules,
  fetchEngagementAnalytics,
  fetchGeoClusters,
  fetchRealtimeAnalytics,
} from '@/features/active-users';
import {
  EMPTY_ENGAGEMENT_ANALYTICS,
  EMPTY_REALTIME_ANALYTICS,
} from '@/features/active-users/data/active-users.types';
import { ADMIN_PERMISSIONS } from '@/lib/auth/rbac/permissions';
import { requirePagePermission } from '@/lib/auth/rbac/server';

export default async function ActiveUsersPage() {
  const t = await getTranslations('activeUsers');
  const cookieStore = await cookies();
  const initialSidebarCollapsed = cookieStore.get(DESKTOP_SIDEBAR_COOKIE_KEY)?.value === '1';

  await requirePagePermission(ADMIN_PERMISSIONS['analytics:read']);

  const listParams = new URLSearchParams({ page: '1', limit: '50' });
  const [summary, list, engagement, realtime, geoClusters, alertRules] = await Promise.all([
    fetchActiveUsersSummary().catch(() => null),
    fetchActiveUsersList(listParams).catch(() => ({ rows: [], total: 0 })),
    fetchEngagementAnalytics().catch(() => EMPTY_ENGAGEMENT_ANALYTICS),
    fetchRealtimeAnalytics().catch(() => EMPTY_REALTIME_ANALYTICS),
    fetchGeoClusters().catch(() => []),
    fetchAlertRules().catch(() => []),
  ]);

  return (
    <AdminShell title={t('pageTitle')} activeItem="active-users" initialSidebarCollapsed={initialSidebarCollapsed}>
      <ActiveUsersWorkspace
        initialSummary={summary}
        initialRows={list.rows}
        engagement={engagement}
        realtime={realtime}
        geoClusters={geoClusters}
        alertRules={alertRules}
      />
    </AdminShell>
  );
}
