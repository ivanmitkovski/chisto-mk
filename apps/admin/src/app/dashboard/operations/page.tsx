import { getTranslations } from 'next-intl/server';
import { AdminShell } from '@/features/admin-shell';
import { readDashboardShellState } from '@/features/admin-shell/server';
import { OperationsLiveProvider, OperationsWorkspace } from '@/features/operations';
import { getOperationsSnapshot } from '@/features/operations';
import { ADMIN_PERMISSIONS } from '@/lib/auth/rbac/permissions';
import { requirePagePermission } from '@/lib/auth/rbac/server';

export default async function OperationsPage() {
  const t = await getTranslations('operations');
  const { initialSidebarCollapsed } = await readDashboardShellState();

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
