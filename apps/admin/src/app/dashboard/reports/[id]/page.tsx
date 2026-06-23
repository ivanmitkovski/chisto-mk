import { notFound } from 'next/navigation';
import { getTranslations } from 'next-intl/server';
import { AdminShell } from '@/features/admin-shell';
import { readDashboardShellState } from '@/features/admin-shell/server';
import { SectionState } from '@/components/ui';
import { ApiError } from '@/lib/api';
import { ADMIN_PERMISSIONS } from '@/lib/auth/rbac/permissions';
import { requirePagePermission } from '@/lib/auth/rbac/server';
import { getMeProfile } from '@/features/auth/data/me-adapter';
import { getReportDetail } from '@/features/reports/data/reports-adapter';
import { ReportDetailPage } from '@/features/reports';
import { canAssignToOthers } from '@/features/reports/utils/can-assign-to-others';
import { listEligibleModerators } from '@/features/reports/data/eligible-moderators';
import type { EligibleModerator } from '@/features/reports/data/eligible-moderators';
import { handleServerLoadError } from '@/lib/server/handle-server-load-error';
import styles from './report-detail-page.module.css';


type ReportDetailPageProps = {
  params: Promise<{ id: string }>;
};

function reportErrorShell(
  message: string,
  title: string,
  initialSidebarCollapsed: boolean,
) {
  return (
    <AdminShell
      title={title}
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
  await requirePagePermission(ADMIN_PERMISSIONS['reports:read']);
  const tReports = await getTranslations('reports');
  const { initialSidebarCollapsed } = await readDashboardShellState();
  const { id } = await params;

  let report;
  let me: Awaited<ReturnType<typeof getMeProfile>> | null = null;
  let eligibleModerators: EligibleModerator[] = [];
  try {
    [report, me] = await Promise.all([getReportDetail(id), getMeProfile()]);
    if (me && canAssignToOthers(me.role)) {
      eligibleModerators = await listEligibleModerators();
    }
  } catch (error) {
    if (error instanceof ApiError && (error.code === 'REPORT_NOT_FOUND' || error.status === 404)) {
      notFound();
    }
    const message = await handleServerLoadError(error, { fallbackMessageKey: 'unableToLoadReport' });
    return reportErrorShell(message, tReports('detailTitle'), initialSidebarCollapsed);
  }

  return (
    <AdminShell
      title={`${report.reportNumber} · ${report.title}`}
      activeItem="reports"
      initialSidebarCollapsed={initialSidebarCollapsed}
    >
      <ReportDetailPage
        report={report}
        {...(me?.id ? { moderatorId: me.id } : {})}
        {...(me
          ? {
              moderatorDisplayName: `${me.firstName} ${me.lastName}`.trim() || me.email,
              viewerRole: me.role,
            }
          : {})}
        eligibleModerators={eligibleModerators}
      />
    </AdminShell>
  );
}
