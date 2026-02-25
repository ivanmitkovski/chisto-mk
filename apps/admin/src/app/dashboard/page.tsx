import { cookies } from 'next/headers';
import { AdminShell } from '@/features/admin-shell';
import { DESKTOP_SIDEBAR_COOKIE_KEY } from '@/features/admin-shell/constants';
import { getDashboardStats, StatsOverview } from '@/features/dashboard-overview';
import { getReports, ReportsTable } from '@/features/reports';

export default async function DashboardPage() {
  const cookieStore = await cookies();
  const initialSidebarCollapsed = cookieStore.get(DESKTOP_SIDEBAR_COOKIE_KEY)?.value === '1';
  const [stats, reports] = await Promise.all([getDashboardStats(), getReports()]);

  return (
    <AdminShell title="Overview" activeItem="dashboard" initialSidebarCollapsed={initialSidebarCollapsed}>
      <StatsOverview cards={stats} />
      <ReportsTable rows={reports} />
    </AdminShell>
  );
}
