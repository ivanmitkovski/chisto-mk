import { getTranslations } from 'next-intl/server';
import { AdminShell } from '@/features/admin-shell';
import { readDashboardShellState } from '@/features/admin-shell/server';
import { NotificationsDashboardPageClient } from '@/features/notifications';
import { ADMIN_PERMISSIONS } from '@/lib/auth/rbac/permissions';
import { requirePagePermission } from '@/lib/auth/rbac/server';

export default async function NotificationsPage() {
  await requirePagePermission(ADMIN_PERMISSIONS['notifications:read']);
  const t = await getTranslations('notifications');
  const { initialSidebarCollapsed } = await readDashboardShellState();

  return (
    <AdminShell title={t('pageTitle')} activeItem="notifications" initialSidebarCollapsed={initialSidebarCollapsed}>
      <NotificationsDashboardPageClient />
    </AdminShell>
  );
}
