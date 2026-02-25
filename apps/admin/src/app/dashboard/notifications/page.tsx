import { cookies } from 'next/headers';
import { AdminShell } from '@/features/admin-shell';
import { DESKTOP_SIDEBAR_COOKIE_KEY } from '@/features/admin-shell/constants';
import { NotificationsCenter } from '@/features/notifications';

export default async function NotificationsPage() {
  const cookieStore = await cookies();
  const initialSidebarCollapsed = cookieStore.get(DESKTOP_SIDEBAR_COOKIE_KEY)?.value === '1';

  return (
    <AdminShell title="Notifications" activeItem="dashboard" initialSidebarCollapsed={initialSidebarCollapsed}>
      <NotificationsCenter />
    </AdminShell>
  );
}
