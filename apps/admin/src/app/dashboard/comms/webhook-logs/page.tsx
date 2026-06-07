import { cookies } from 'next/headers';
import { getTranslations } from 'next-intl/server';
import { AdminShell } from '@/features/admin-shell';
import { DESKTOP_SIDEBAR_COOKIE_KEY } from '@/features/admin-shell';
import { SectionState } from '@/components/ui';
import { WebhookLogsWorkspace, getWebhookLogs } from '@/features/comms';
import { ADMIN_PERMISSIONS } from '@/lib/auth/rbac/permissions';
import { requirePagePermission } from '@/lib/auth/rbac/server';
import { handleServerLoadError } from '@/lib/server/handle-server-load-error';

type PageProps = {
  searchParams: Promise<{ page?: string; action?: string }>;
};

export default async function WebhookLogsPage(props: PageProps) {
  await requirePagePermission(ADMIN_PERMISSIONS['comms:read']);
  const t = await getTranslations('comms.webhookLogs');
  const cookieStore = await cookies();
  const initialSidebarCollapsed = cookieStore.get(DESKTOP_SIDEBAR_COOKIE_KEY)?.value === '1';
  const params = await props.searchParams;
  const page = Math.max(1, parseInt(params.page ?? '1', 10) || 1);
  const action = params.action ?? '';

  try {
    const result = await getWebhookLogs({
      page,
      limit: 50,
      ...(action ? { action } : {}),
    });
    return (
      <AdminShell
        title={t('pageTitle')}
        activeItem="webhook-logs"
        initialSidebarCollapsed={initialSidebarCollapsed}
      >
        <WebhookLogsWorkspace initialData={result.data} initialMeta={result.meta} initialAction={action} />
      </AdminShell>
    );
  } catch (error) {
    const message = await handleServerLoadError(error, { fallbackMessageKey: 'unableToLoadWebhookLogs' });
    return (
      <AdminShell
        title={t('pageTitle')}
        activeItem="webhook-logs"
        initialSidebarCollapsed={initialSidebarCollapsed}
      >
        <SectionState variant="error" message={message} />
      </AdminShell>
    );
  }
}
