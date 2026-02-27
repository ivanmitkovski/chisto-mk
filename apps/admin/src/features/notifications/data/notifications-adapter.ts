import { apiFetch } from '@/lib/api';
import { getAdminAuthTokenFromCookies } from '@/features/auth/lib/admin-auth-server';
import type { AdminNotification } from '../types';

type AdminNotificationsListResponse = {
  data: AdminNotification[];
  meta: {
    page: number;
    limit: number;
    total: number;
    unreadCount: number;
  };
};

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
    items: response.data,
    unreadCount: response.meta.unreadCount,
  };
}

