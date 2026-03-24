import { cookies } from 'next/headers';
import { notFound } from 'next/navigation';
import { AdminShell } from '@/features/admin-shell';
import { DESKTOP_SIDEBAR_COOKIE_KEY } from '@/features/admin-shell/constants';
import { SectionState } from '@/components/ui';
import { ApiError } from '@/lib/api';
import { getReportDetail } from '@/features/reports';
import { ReportDetailPage } from '@/features/reports/components/report-detail-page';
import styles from './report-detail-page.module.css';


type ReportDetailPageProps = {
  params: Promise<{ id: string }>;
};

function reportErrorShell(message: string, initialSidebarCollapsed: boolean) {
  return (
    <AdminShell
      title="Report"
      activeItem="reports"
      initialSidebarCollapsed={initialSidebarCollapsed}
    >
      <div className={styles.page}>
        <SectionState variant="error" message={message} />
      </div>
    </AdminShell>
  );
}

export default async function ReportDetailRoute({ params }: ReportDetailPageProps) {
  const cookieStore = await cookies();
  const initialSidebarCollapsed = cookieStore.get(DESKTOP_SIDEBAR_COOKIE_KEY)?.value === '1';
  const { id } = await params;

  let report;
  try {
    report = await getReportDetail(id);
  } catch (error) {
    if (error instanceof ApiError && (error.code === 'REPORT_NOT_FOUND' || error.status === 404)) {
      notFound();
    }
    return reportErrorShell(
      'Unable to load this report. Please try again or sign in again.',
      initialSidebarCollapsed,
    );
  }

  return (
    <AdminShell
      title={`${report.reportNumber} · ${report.title}`}
      activeItem="reports"
      initialSidebarCollapsed={initialSidebarCollapsed}
    >
      <ReportDetailPage report={report} />
    </AdminShell>
  );
}
