import {
  DashboardSSEClient,
  DashboardSSEProvider,
  DashboardPollingFallback,
  NewReportSoundEffect,
} from '@/features/dashboard-overview';
import { DashboardPermissionsProvider } from '@/features/admin-shell';
import { DashboardLayoutError } from '@/features/admin-shell/components/dashboard-layout-error';
import { MfaReminderBanner } from '@/features/admin-shell/components/mfa-reminder-banner';
import { getMeProfile } from '@/features/auth';
import { handleServerLoadError } from '@/lib/server/handle-server-load-error';

/** Ensure RSC reads request cookies (auth token for API calls, notifications). */
export const dynamic = 'force-dynamic';
import { NotificationsProvider } from '@/features/notifications';
import { NotificationsQuerySync } from '@/features/notifications';
import { getAdminNotifications } from '@/features/notifications';

export default async function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  let role: string | null = null;
  let mfaEnabled = true;
  let profileLoadError: string | null = null;

  try {
    const me = await getMeProfile();
    role = me.role ?? null;
    mfaEnabled = me.mfaEnabled ?? false;
  } catch (error) {
    try {
      profileLoadError = await handleServerLoadError(error);
    } catch {
      profileLoadError = null;
    }
  }

  if (profileLoadError) {
    return <DashboardLayoutError description={profileLoadError} />;
  }

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
    <DashboardPermissionsProvider role={role}>
      <NotificationsProvider
        initialItems={initialItems}
        initialUnreadCount={initialUnreadCount}
      >
        <NotificationsQuerySync />
        <DashboardSSEProvider>
          <DashboardSSEClient />
          <NewReportSoundEffect />
          <DashboardPollingFallback />
          <MfaReminderBanner mfaEnabled={mfaEnabled} />
          {children}
        </DashboardSSEProvider>
      </NotificationsProvider>
    </DashboardPermissionsProvider>
  );
}
