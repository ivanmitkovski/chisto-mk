import { getTranslations } from 'next-intl/server';
import { AdminShell } from '@/features/admin-shell';
import { readDashboardShellState } from '@/features/admin-shell/server';
import { PageHeader, SectionState } from '@/components/ui';
import {
  getUgcModerationReport,
  getUgcModerationReports,
  UgcModerationWorkspace,
} from '@/features/moderation';
import { ADMIN_PERMISSIONS } from '@/lib/auth/rbac/permissions';
import { requirePagePermission } from '@/lib/auth/rbac/server';
import { handleServerLoadError } from '@/lib/server/handle-server-load-error';

const UGC_PAGE_SIZE = 50;

type UgcModerationPageProps = {
  searchParams: Promise<{
    reportId?: string;
    page?: string;
    status?: string;
    subjectType?: string;
    search?: string;
  }>;
};

export default async function UgcModerationPage({ searchParams }: UgcModerationPageProps) {
  await requirePagePermission(ADMIN_PERMISSIONS['moderation:read']);
  const tNav = await getTranslations('nav');
  const t = await getTranslations('moderation');
  const { initialSidebarCollapsed } = await readDashboardShellState();
  const params = await searchParams;
  const page = Math.max(1, Number.parseInt(params.page ?? '1', 10) || 1);
  const status = params.status ?? '';
  const subjectType = params.subjectType ?? '';
  const search = params.search?.trim() ?? '';
  const targetReportId = params.reportId ?? null;

  let content: React.ReactNode;
  try {
    const reportsResult = await getUgcModerationReports({
      page,
      limit: UGC_PAGE_SIZE,
      ...(status ? { status } : {}),
      ...(subjectType ? { subjectType } : {}),
      ...(search ? { search } : {}),
    });

    let reports = reportsResult.data;
    let initialSelectedReportId: string | null = null;

    if (targetReportId) {
      const inList = reports.some((report) => report.id === targetReportId);
      if (inList) {
        initialSelectedReportId = targetReportId;
      } else {
        try {
          const targetReport = await getUgcModerationReport(targetReportId);
          reports = [targetReport, ...reports];
          initialSelectedReportId = targetReport.id;
        } catch {
          // Ignore deep-link preselect failure and keep default list behavior.
        }
      }
    }

    content =
      reports.length === 0 ? (
        <SectionState variant="empty" message={t('empty')} />
      ) : (
        <UgcModerationWorkspace
          initialReports={reports}
          initialMeta={reportsResult.meta}
          initialSelectedReportId={initialSelectedReportId}
          initialStatusFilter={status}
          initialSubjectTypeFilter={subjectType}
          initialSearch={search}
        />
      );
  } catch (error) {
    const message = await handleServerLoadError(error, { fallbackMessageKey: 'unableToLoadUgcReports' });
    content = <SectionState variant="error" message={message} />;
  }

  return (
    <AdminShell title={tNav('moderation')} activeItem="moderation" initialSidebarCollapsed={initialSidebarCollapsed}>
      <PageHeader title={t('pageHeaderTitle')} description={t('pageDescription')} />
      {content}
    </AdminShell>
  );
}
