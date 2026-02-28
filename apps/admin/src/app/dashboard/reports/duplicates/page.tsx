import { cookies } from 'next/headers';
import { AdminShell } from '@/features/admin-shell';
import { DESKTOP_SIDEBAR_COOKIE_KEY } from '@/features/admin-shell/constants';
import { SectionState } from '@/components/ui';
import {
  DuplicateReportGroup,
  DuplicateReportsWorkspace,
  getDuplicateReportGroup,
  getDuplicateReportGroups,
} from '@/features/reports';

function duplicatesErrorShell(initialSidebarCollapsed: boolean, message: string) {
  return (
    <AdminShell title="Duplicate Reports" activeItem="duplicates" initialSidebarCollapsed={initialSidebarCollapsed}>
      <SectionState variant="error" message={message} />
    </AdminShell>
  );
}

type DuplicateReportsPageProps = {
  searchParams: Promise<{
    reportId?: string;
  }>;
};

export default async function DuplicateReportsPage({ searchParams }: DuplicateReportsPageProps) {
  const cookieStore = await cookies();
  const initialSidebarCollapsed = cookieStore.get(DESKTOP_SIDEBAR_COOKIE_KEY)?.value === '1';
  const resolvedSearchParams = await searchParams;

  let duplicateGroups: Awaited<ReturnType<typeof getDuplicateReportGroups>>;
  try {
    duplicateGroups = await getDuplicateReportGroups();
  } catch {
    return duplicatesErrorShell(
      initialSidebarCollapsed,
      'Unable to load duplicate reports. Please try again or sign in again.',
    );
  }

  let initialSelectedGroupId: string | null = null;
  const targetReportId = resolvedSearchParams.reportId;

  if (targetReportId) {
    try {
      const targetGroup = await getDuplicateReportGroup(targetReportId);
      initialSelectedGroupId = targetGroup.primaryReport.id;

      const hasGroup = duplicateGroups.some(
        (group) => group.primaryReport.id === targetGroup.primaryReport.id,
      );

      if (!hasGroup) {
        const mergedGroups: DuplicateReportGroup[] = [targetGroup, ...duplicateGroups];
        duplicateGroups = mergedGroups;
      }
    } catch {
      // Ignore deep-link preselect failure and keep default list behavior.
    }
  }

  return (
    <AdminShell title="Duplicate Reports" activeItem="duplicates" initialSidebarCollapsed={initialSidebarCollapsed}>
      <DuplicateReportsWorkspace
        initialGroups={duplicateGroups}
        initialSelectedGroupId={initialSelectedGroupId}
      />
    </AdminShell>
  );
}
