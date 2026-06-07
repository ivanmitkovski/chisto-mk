import { cookies } from 'next/headers';
import { getTranslations } from 'next-intl/server';
import { AdminShell } from '@/features/admin-shell';
import { DESKTOP_SIDEBAR_COOKIE_KEY } from '@/features/admin-shell';
import { AppConfigWorkspace, getAppConfigSnapshot } from '@/features/app-config';
import { SectionState } from '@/components/ui';
import { ADMIN_PERMISSIONS } from '@/lib/auth/rbac/permissions';
import { requirePagePermission } from '@/lib/auth/rbac/server';
import { handleServerLoadError } from '@/lib/server/handle-server-load-error';

export default async function AppConfigPage() {
  const t = await getTranslations('appConfig');
  const cookieStore = await cookies();
  const initialSidebarCollapsed = cookieStore.get(DESKTOP_SIDEBAR_COOKIE_KEY)?.value === '1';

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
