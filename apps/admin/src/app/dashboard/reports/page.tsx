import { cookies } from 'next/headers';
import { AdminShell } from '@/features/admin-shell';
import { DESKTOP_SIDEBAR_COOKIE_KEY } from '@/features/admin-shell/constants';
import { getReportDetail, ReportReviewCard } from '@/features/reports';

type ReportsPageProps = {
  searchParams: Promise<{
    reportId?: string;
  }>;
};

export default async function ReportsPage({ searchParams }: ReportsPageProps) {
  const cookieStore = await cookies();
  const initialSidebarCollapsed = cookieStore.get(DESKTOP_SIDEBAR_COOKIE_KEY)?.value === '1';
  const resolvedSearchParams = await searchParams;
  const reportId = resolvedSearchParams.reportId ?? 'r-1';
  const report = await getReportDetail(reportId);

  return (
    <AdminShell title="Reports" activeItem="reports" initialSidebarCollapsed={initialSidebarCollapsed}>
      <ReportReviewCard report={report} />
    </AdminShell>
  );
}
