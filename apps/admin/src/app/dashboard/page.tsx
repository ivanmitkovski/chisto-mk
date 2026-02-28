import { cookies } from 'next/headers';
import { AdminShell } from '@/features/admin-shell';
import { DESKTOP_SIDEBAR_COOKIE_KEY } from '@/features/admin-shell/constants';
import { SectionState } from '@/components/ui';
import { getDashboardStats, StatsOverview } from '@/features/dashboard-overview';
import { getReports, ReportsTable } from '@/features/reports';
import { getAdminNotifications } from '@/features/notifications';

export default async function DashboardPage() {
  const cookieStore = await cookies();
  const initialSidebarCollapsed = cookieStore.get(DESKTOP_SIDEBAR_COOKIE_KEY)?.value === '1';

  let data: {
    notifications: Awaited<ReturnType<typeof getAdminNotifications>>['items'];
    stats: Awaited<ReturnType<typeof getDashboardStats>>;
    reports: Awaited<ReturnType<typeof getReports>>;
  };

  try {
    const [notifResult, statsData, reportsData] = await Promise.all([
      getAdminNotifications(),
      getDashboardStats(),
      getReports(),
    ]);
    data = {
      notifications: notifResult.items,
      stats: statsData,
      reports: reportsData,
    };
  } catch {
    return (
      <AdminShell
        title="Overview"
        activeItem="dashboard"
        initialSidebarCollapsed={initialSidebarCollapsed}
        initialTopBarNotifications={[]}
      >
        <SectionState
          variant="error"
          message="Unable to load the dashboard. Please try again or sign in again."
        />
      </AdminShell>
    );
  }

  return (
    <AdminShell
      title="Overview"
      activeItem="dashboard"
      initialSidebarCollapsed={initialSidebarCollapsed}
      initialTopBarNotifications={data.notifications.slice(0, 3)}
    >
      <StatsOverview cards={data.stats} />
      <ReportsTable rows={data.reports} />
    </AdminShell>
  );
}
