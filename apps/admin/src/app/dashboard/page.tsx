import { AdminShell } from '@/features/admin-shell';
import { getDashboardStats, StatsOverview } from '@/features/dashboard-overview';
import { getReports, ReportsTable } from '@/features/reports';

export default async function DashboardPage() {
  const [stats, reports] = await Promise.all([getDashboardStats(), getReports()]);

  return (
    <AdminShell title="Overview" activeItem="dashboard">
      <StatsOverview cards={stats} />
      <ReportsTable rows={reports} />
    </AdminShell>
  );
}
