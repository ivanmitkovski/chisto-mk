import {
  DashboardSSEClient,
  DashboardSSEProvider,
  DashboardPollingFallback,
} from '@/features/dashboard-overview';
import { AdminPreferencesInit } from '@/features/settings/components/admin-preferences-init';
import { NotificationsProvider } from '@/features/notifications/context/notifications-context';
import { NotificationsQuerySync } from '@/features/notifications/components/notifications-query-sync';
import { getAdminNotifications } from '@/features/notifications';

export default async function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  let initialItems: { id: string; title: string; message: string; timeLabel: string; isUnread: boolean; href?: string }[] = [];
  let initialUnreadCount = 0;

  try {
    const result = await getAdminNotifications();
    initialItems = result.items.slice(0, 10).map((item) => {
      const base = {
        id: item.id,
        title: item.title,
        message: item.message,
        timeLabel: item.timeLabel,
        isUnread: item.isUnread,
      };
      return item.href ? { ...base, href: item.href } : base;
    });
    initialUnreadCount = result.unreadCount;
  } catch {
    // Leave empty on auth or network error
  }

  return (
    <NotificationsProvider
      initialItems={initialItems}
      initialUnreadCount={initialUnreadCount}
    >
      <AdminPreferencesInit />
      <NotificationsQuerySync />
      <DashboardSSEProvider>
        <DashboardSSEClient />
        <DashboardPollingFallback />
        {children}
      </DashboardSSEProvider>
    </NotificationsProvider>
  );
}
