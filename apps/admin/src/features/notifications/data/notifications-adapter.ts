import type { IconName } from '@/components/ui';
import { apiFetch } from '@/lib/api';
import { getAdminAuthTokenFromCookies } from '@/features/auth/lib/admin-auth-server';
import type { AdminNotification, NotificationTone } from '../types';

type AdminNotificationApiItem = {
  id: string;
  title: string;
  message: string;
  timeLabel: string;
  tone: string;
  category: string;
  isUnread: boolean;
  href: string | null;
};

type AdminNotificationsListResponse = {
  data: AdminNotificationApiItem[];
  meta: {
    page: number;
    limit: number;
    total: number;
    unreadCount: number;
  };
};

function toneCategoryToIcon(tone: string, category: string): IconName {
  if (category === 'reports') return 'document-text';
  if (category === 'system') return 'shield';
  if (category === 'analytics') return 'document-duplicate';
  if (tone === 'warning') return 'alert-triangle';
  if (tone === 'success') return 'check';
  return 'info';
}

function mapApiItemToAdminNotification(item: AdminNotificationApiItem): AdminNotification {
  return {
    id: item.id,
    title: item.title,
    message: item.message,
    timeLabel: item.timeLabel,
    tone: item.tone as NotificationTone,
    isUnread: item.isUnread,
    category: item.category as AdminNotification['category'],
    icon: toneCategoryToIcon(item.tone, item.category),
    ...(item.href && { href: item.href }),
  };
}

export async function getAdminNotifications(): Promise<{
  items: AdminNotification[];
  unreadCount: number;
}> {
  const token = await getAdminAuthTokenFromCookies();

  const response = await apiFetch<AdminNotificationsListResponse>('/admin/notifications', {
    method: 'GET',
    authToken: token,
  });

  return {
    items: response.data.map(mapApiItemToAdminNotification),
    unreadCount: response.meta.unreadCount,
  };
}

