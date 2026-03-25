import {
  DashboardSSEClient,
  DashboardSSEProvider,
  DashboardPollingFallback,
  NewReportSoundEffect,
} from '@/features/dashboard-overview';

/** Ensure RSC reads request cookies (auth token for API calls, notifications). */
export const dynamic = 'force-dynamic';
import { AdminPreferencesInit } from '@/features/settings/components/admin-preferences-init';
import { NotificationsProvider } from '@/features/notifications/context/notifications-context';
import { NotificationsQuerySync } from '@/features/notifications/components/notifications-query-sync';
import { getAdminNotifications } from '@/features/notifications';

export default async function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  let initialItems: {
    id: string;
    title: string;
    message: string;
    timeLabel: string;
    createdAt?: string;
    isUnread: boolean;
    href?: string;
  }[] = [];
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
        ...(item.createdAt && { createdAt: item.createdAt }),
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
        <NewReportSoundEffect />
        <DashboardPollingFallback />
        {children}
      </DashboardSSEProvider>
    </NotificationsProvider>
  );
}
