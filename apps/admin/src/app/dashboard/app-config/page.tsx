import { getTranslations } from 'next-intl/server';
import { AdminShell } from '@/features/admin-shell';
import { readDashboardShellState } from '@/features/admin-shell/server';
import { AppConfigWorkspace, getAppConfigSnapshot } from '@/features/app-config';
import { SectionState } from '@/components/ui';
import { ADMIN_PERMISSIONS } from '@/lib/auth/rbac/permissions';
import { requirePagePermission } from '@/lib/auth/rbac/server';
import { handleServerLoadError } from '@/lib/server/handle-server-load-error';

export default async function AppConfigPage() {
  const t = await getTranslations('appConfig');
  const { initialSidebarCollapsed } = await readDashboardShellState();

  await requirePagePermission(ADMIN_PERMISSIONS['app-config:read']);
  try {
    const snapshot = await getAppConfigSnapshot();
    return (
      <AdminShell title={t('pageTitle')} activeItem="app-config" initialSidebarCollapsed={initialSidebarCollapsed}>
        <AppConfigWorkspace initialSnapshot={snapshot} />
      </AdminShell>
    );
  } catch (error) {
    const message = await handleServerLoadError(error, { fallbackMessageKey: 'unableToLoadAppConfig' });
    return (
      <AdminShell title={t('pageTitle')} activeItem="app-config" initialSidebarCollapsed={initialSidebarCollapsed}>
        <SectionState variant="error" message={message} />
      </AdminShell>
    );
  }
}
