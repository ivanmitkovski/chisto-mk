import { cookies } from 'next/headers';
import { AdminShell } from '@/features/admin-shell';
import { DESKTOP_SIDEBAR_COOKIE_KEY } from '@/features/admin-shell/constants';
import { PageHeader, SectionState } from '@/components/ui';
import { ApiError } from '@/lib/api';
import { getUgcModerationReports } from '@/features/moderation/data/ugc-moderation-adapter';
import { UgcModerationWorkspace } from '@/features/moderation/components/ugc-moderation-workspace';

export default async function UgcModerationPage() {
  const cookieStore = await cookies();
  const initialSidebarCollapsed = cookieStore.get(DESKTOP_SIDEBAR_COOKIE_KEY)?.value === '1';

  let content: React.ReactNode;
  try {
    const reports = await getUgcModerationReports();
    content =
      reports.data.length === 0 ? (
        <SectionState variant="empty" message="No UGC reports are waiting for review." />
      ) : (
        <UgcModerationWorkspace initialReports={reports.data} />
      );
  } catch (error) {
    const missingEndpoint =
      error instanceof ApiError && (error.status === 404 || error.code === 'NOT_FOUND');
    content = (
      <SectionState
        variant="error"
        message={
          missingEndpoint
            ? 'UGC moderation API is not available yet. The admin route is ready and will activate when /admin/moderation/ugc-reports ships.'
            : 'Unable to load UGC reports.'
        }
      />
    );
  }

  return (
    <AdminShell title="UGC Moderation" activeItem="moderation" initialSidebarCollapsed={initialSidebarCollapsed}>
      <PageHeader
        title="UGC moderation"
        description="Triage citizen reports for comments, chats, users, sites, and events."
      />
      {content}
    </AdminShell>
  );
}
