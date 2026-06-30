import { getTranslations } from 'next-intl/server';
import { AdminShell } from '@/features/admin-shell';
import { readDashboardShellState } from '@/features/admin-shell/server';
import { SectionState } from '@/components/ui';
import { EmailSuppressionsWorkspace, getEmailSuppressions } from '@/features/comms';
import { ADMIN_PERMISSIONS } from '@/lib/auth/rbac/permissions';
import { requirePagePermission } from '@/lib/auth/rbac/server';
import { handleServerLoadError } from '@/lib/server/handle-server-load-error';

type PageProps = {
  searchParams: Promise<{ page?: string; search?: string; reason?: string; source?: string }>;
};

export default async function EmailSuppressionsPage(props: PageProps) {
  await requirePagePermission(ADMIN_PERMISSIONS['comms:read']);
  const t = await getTranslations('comms.emailSuppressions');
  const { initialSidebarCollapsed } = await readDashboardShellState();
  const params = await props.searchParams;
  const page = Math.max(1, parseInt(params.page ?? '1', 10) || 1);
  const search = params.search ?? '';
  const reason = params.reason ?? '';
  const source = params.source ?? '';

  try {
    const result = await getEmailSuppressions({
      page,
      limit: 50,
      ...(search ? { search } : {}),
      ...(reason ? { reason } : {}),
      ...(source ? { source } : {}),
    });
    return (
      <AdminShell
        title={t('pageTitle')}
        activeItem="email-suppressions"
        initialSidebarCollapsed={initialSidebarCollapsed}
      >
        <EmailSuppressionsWorkspace
          initialData={result.data}
          initialMeta={result.meta}
          initialSearch={search}
          initialReason={reason}
          initialSource={source}
        />
      </AdminShell>
    );
  } catch (error) {
    const message = await handleServerLoadError(error, { fallbackMessageKey: 'unableToLoadEmailSuppressions' });
    return (
      <AdminShell
        title={t('pageTitle')}
        activeItem="email-suppressions"
        initialSidebarCollapsed={initialSidebarCollapsed}
      >
        <SectionState variant="error" message={message} />
      </AdminShell>
    );
  }
}
