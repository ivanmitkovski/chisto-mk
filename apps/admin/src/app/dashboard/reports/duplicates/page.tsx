import { cookies } from 'next/headers';
import { getTranslations } from 'next-intl/server';
import { AdminShell } from '@/features/admin-shell';
import { DESKTOP_SIDEBAR_COOKIE_KEY } from '@/features/admin-shell';
import { SectionState } from '@/components/ui';
import {
  DuplicateReportsWorkspace,
  getDuplicateReportGroup,
  getDuplicateReportGroups,
} from '@/features/reports';
import { ADMIN_PERMISSIONS } from '@/lib/auth/rbac/permissions';
import { requirePagePermission } from '@/lib/auth/rbac/server';
import { handleServerLoadError } from '@/lib/server/handle-server-load-error';

const DUPLICATE_GROUPS_PAGE_SIZE = 20;

type DuplicateReportsPageProps = {
  searchParams: Promise<{
    reportId?: string;
    page?: string;
  }>;
};

export default async function DuplicateReportsPage({ searchParams }: DuplicateReportsPageProps) {
  await requirePagePermission(ADMIN_PERMISSIONS['reports:read']);
  const tNav = await getTranslations('nav');
  const t = await getTranslations('reports.duplicates');
  const cookieStore = await cookies();
  const initialSidebarCollapsed = cookieStore.get(DESKTOP_SIDEBAR_COOKIE_KEY)?.value === '1';
  const resolvedSearchParams = await searchParams;
  const page = Math.max(1, Number.parseInt(resolvedSearchParams.page ?? '1', 10) || 1);

  let duplicateGroupsResult: Awaited<ReturnType<typeof getDuplicateReportGroups>>;
  try {
    duplicateGroupsResult = await getDuplicateReportGroups({ page, limit: DUPLICATE_GROUPS_PAGE_SIZE });
  } catch (error) {
    const message = await handleServerLoadError(error, { fallbackMessageKey: 'unableToLoadDuplicates' });
    return (
      <AdminShell title={tNav('duplicates')} activeItem="duplicates" initialSidebarCollapsed={initialSidebarCollapsed}>
        <SectionState variant="error" message={message} />
      </AdminShell>
    );
  }

  let initialSelectedGroupId: string | null = null;
  const targetReportId = resolvedSearchParams.reportId;

  if (targetReportId) {
    try {
      const targetGroup = await getDuplicateReportGroup(targetReportId);
      initialSelectedGroupId = targetGroup.primaryReport.id;

      const hasGroup = duplicateGroupsResult.data.some(
        (group) => group.primaryReport.id === targetGroup.primaryReport.id,
      );

      if (!hasGroup) {
        duplicateGroupsResult = {
          ...duplicateGroupsResult,
          data: [targetGroup, ...duplicateGroupsResult.data],
        };
      }
    } catch {
      // Ignore deep-link preselect failure and keep default list behavior.
    }
  }

  return (
    <AdminShell title={tNav('duplicates')} activeItem="duplicates" initialSidebarCollapsed={initialSidebarCollapsed}>
      {duplicateGroupsResult.data.length === 0 ? (
        <SectionState variant="empty" message={t('empty')} />
      ) : (
        <DuplicateReportsWorkspace
          initialGroups={duplicateGroupsResult.data}
          initialMeta={duplicateGroupsResult.meta}
          initialSelectedGroupId={initialSelectedGroupId}
        />
      )}
    </AdminShell>
  );
}
