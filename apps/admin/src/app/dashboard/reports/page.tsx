import { cookies } from 'next/headers';
import { AdminShell } from '@/features/admin-shell';
import { DESKTOP_SIDEBAR_COOKIE_KEY } from '@/features/admin-shell/constants';
import { SectionState } from '@/components/ui';
import { ApiError } from '@/lib/api';
import { getReportDetail, getReports, ReportReviewCard } from '@/features/reports';

type ReportsPageProps = {
  searchParams: Promise<{
    reportId?: string;
  }>;
};

function reportsErrorShell(
  initialSidebarCollapsed: boolean,
  message: string,
) {
  return (
    <AdminShell title="Reports" activeItem="reports" initialSidebarCollapsed={initialSidebarCollapsed}>
      <SectionState variant="error" message={message} />
    </AdminShell>
  );
}

export default async function ReportsPage({ searchParams }: ReportsPageProps) {
  const cookieStore = await cookies();
  const initialSidebarCollapsed = cookieStore.get(DESKTOP_SIDEBAR_COOKIE_KEY)?.value === '1';
  const resolvedSearchParams = await searchParams;

  let reports: Awaited<ReturnType<typeof getReports>>;
  try {
    [reports] = await Promise.all([getReports()]);
  } catch {
    return reportsErrorShell(
      initialSidebarCollapsed,
      'Unable to load reports. Please try again or sign in again.',
    );
  }

  if (!reports.length) {
    return (
      <AdminShell title="Reports" activeItem="reports" initialSidebarCollapsed={initialSidebarCollapsed}>
        <SectionState variant="empty" message="No reports are available for moderation yet." />
      </AdminShell>
    );
  }

  const reportId = resolvedSearchParams.reportId ?? reports[0].id;

  try {
    const report = await getReportDetail(reportId);

    return (
      <AdminShell title="Reports" activeItem="reports" initialSidebarCollapsed={initialSidebarCollapsed}>
        <ReportReviewCard report={report} />
      </AdminShell>
    );
  } catch (error) {
    if (error instanceof ApiError && (error.code === 'REPORT_NOT_FOUND' || error.status === 404)) {
      return (
        <AdminShell title="Reports" activeItem="reports" initialSidebarCollapsed={initialSidebarCollapsed}>
          <SectionState variant="error" message="The selected report could not be found." />
        </AdminShell>
      );
    }

    return reportsErrorShell(
      initialSidebarCollapsed,
      'Unable to load reports. Please try again or sign in again.',
    );
  }
}
