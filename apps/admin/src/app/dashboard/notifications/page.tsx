import { cookies } from 'next/headers';
import { getTranslations } from 'next-intl/server';
import { AdminShell } from '@/features/admin-shell';
import { DESKTOP_SIDEBAR_COOKIE_KEY } from '@/features/admin-shell';
import { NotificationsDashboardPageClient } from '@/features/notifications';
import { ADMIN_PERMISSIONS } from '@/lib/auth/rbac/permissions';
import { requirePagePermission } from '@/lib/auth/rbac/server';

export default async function NotificationsPage() {
  await requirePagePermission(ADMIN_PERMISSIONS['notifications:read']);
  const t = await getTranslations('notifications');
  const cookieStore = await cookies();
  const initialSidebarCollapsed = cookieStore.get(DESKTOP_SIDEBAR_COOKIE_KEY)?.value === '1';

  return (
    <AdminShell title={t('pageTitle')} activeItem="notifications" initialSidebarCollapsed={initialSidebarCollapsed}>
      <NotificationsDashboardPageClient />
    </AdminShell>
  );
}
