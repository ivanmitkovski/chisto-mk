import { cookies } from 'next/headers';
import { getTranslations } from 'next-intl/server';
import { AdminShell } from '@/features/admin-shell';
import { DESKTOP_SIDEBAR_COOKIE_KEY } from '@/features/admin-shell';
import { OperationsLiveProvider, OperationsWorkspace } from '@/features/operations';
import { getOperationsSnapshot } from '@/features/operations';
import { ADMIN_PERMISSIONS } from '@/lib/auth/rbac/permissions';
import { requirePagePermission } from '@/lib/auth/rbac/server';

export default async function OperationsPage() {
  const t = await getTranslations('operations');
  const cookieStore = await cookies();
  const initialSidebarCollapsed = cookieStore.get(DESKTOP_SIDEBAR_COOKIE_KEY)?.value === '1';

  await requirePagePermission(ADMIN_PERMISSIONS['operations:read']);
  const snapshot = await getOperationsSnapshot();

  return (
    <AdminShell title={t('pageTitle')} activeItem="operations" initialSidebarCollapsed={initialSidebarCollapsed}>
      <OperationsLiveProvider>
        <OperationsWorkspace snapshot={snapshot} />
      </OperationsLiveProvider>
    </AdminShell>
  );
}
