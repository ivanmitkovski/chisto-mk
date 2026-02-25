import { AdminShell } from '@/features/admin-shell';
import { getReportDetail, ReportReviewCard } from '@/features/reports';

type ReportsPageProps = {
  searchParams: Promise<{
    reportId?: string;
  }>;
};

export default async function ReportsPage({ searchParams }: ReportsPageProps) {
  const resolvedSearchParams = await searchParams;
  const reportId = resolvedSearchParams.reportId ?? 'r-1';
  const report = await getReportDetail(reportId);

  return (
    <AdminShell title="Reports" activeItem="reports">
      <ReportReviewCard report={report} />
    </AdminShell>
  );
}
