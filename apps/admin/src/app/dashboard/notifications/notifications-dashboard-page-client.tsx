'use client';

import { useQuery } from '@tanstack/react-query';
import {
  adminQueryKeys,
  fetchNotifications,
  type AdminNotificationItem,
} from '@/lib/admin-api-client';
import { NotificationsCenter } from '@/features/notifications';
import { SectionState } from '@/components/ui';
import { ApiConnectionError, ApiError } from '@/lib/api';
import type { AdminNotification } from '@/features/notifications/types';

function mapToAdminNotifications(items: AdminNotificationItem[]): AdminNotification[] {
  return items.map((item) => ({
    id: item.id,
    title: item.title,
    message: item.message,
    timeLabel: item.timeLabel,
    isUnread: item.isUnread,
    tone: item.tone as AdminNotification['tone'],
    category: item.category as AdminNotification['category'],
    icon: item.icon,
    ...(item.createdAt && { createdAt: item.createdAt }),
    ...(item.href && { href: item.href }),
  }));
}

function notificationsFetchErrorMessage(error: unknown): string {
  if (error instanceof ApiConnectionError) {
    return 'Could not reach the API. Check your connection and NEXT_PUBLIC_API_BASE_URL.';
  }
  if (error instanceof ApiError) {
    if (error.status === 401 || error.status === 403) {
      return 'Your session is missing or expired. Sign out and sign in again, then reload.';
    }
    if (error.status >= 500) {
      return 'The API returned an error. Try again in a moment.';
    }
    return `Could not load notifications (HTTP ${error.status}).`;
  }
  if (error instanceof Error && error.message === 'Not signed in') {
    return 'Not signed in. Open the app from the login page and try again.';
  }
  return 'Unable to load notifications right now.';
}

export function NotificationsDashboardPageClient() {
  const { data, isPending, isError, error, dataUpdatedAt } = useQuery({
    queryKey: adminQueryKeys.notifications,
    queryFn: fetchNotifications,
  });

  if (isPending) {
    return <SectionState variant="loading" message="Loading notifications…" />;
  }

  if (isError) {
    return (
      <SectionState variant="error" message={notificationsFetchErrorMessage(error)} />
    );
  }

  if (!data.items.length) {
    return <SectionState variant="empty" message="No notifications are available yet." />;
  }

  return (
    <NotificationsCenter
      key={dataUpdatedAt}
      initialItems={mapToAdminNotifications(data.items)}
    />
  );
}
