import { cookies } from 'next/headers';
import { AdminShell } from '@/features/admin-shell';
import { DESKTOP_SIDEBAR_COOKIE_KEY } from '@/features/admin-shell/constants';
import { NotificationsCenter, getAdminNotifications } from '@/features/notifications';
import { SectionState } from '@/components/ui';
import { ApiError } from '@/lib/api';

export default async function NotificationsPage() {
  const cookieStore = await cookies();
  const initialSidebarCollapsed = cookieStore.get(DESKTOP_SIDEBAR_COOKIE_KEY)?.value === '1';

  try {
    const { items } = await getAdminNotifications();

    if (items.length === 0) {
      return (
        <AdminShell title="Notifications" activeItem="dashboard" initialSidebarCollapsed={initialSidebarCollapsed}>
          <SectionState variant="empty" message="No notifications are available yet." />
        </AdminShell>
      );
    }

    return (
      <AdminShell title="Notifications" activeItem="dashboard" initialSidebarCollapsed={initialSidebarCollapsed}>
        <NotificationsCenter initialItems={items} />
      </AdminShell>
    );
  } catch (error) {
    if (error instanceof ApiError) {
      return (
        <AdminShell title="Notifications" activeItem="dashboard" initialSidebarCollapsed={initialSidebarCollapsed}>
          <SectionState variant="error" message="Unable to load notifications right now." />
        </AdminShell>
      );
    }

    throw error;
  }
}
