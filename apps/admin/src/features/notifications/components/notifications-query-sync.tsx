'use client';

import { useQuery } from '@tanstack/react-query';
import { useEffect, useRef } from 'react';
import { adminQueryKeys, fetchNotifications } from '@/lib/admin-api-client';
import { useNotifications } from '../context/notifications-context';

/**
 * Syncs React Query notifications data to NotificationsContext.
 * When notifications are invalidated (e.g. by SSE), this refetches and updates the context.
 */
export function NotificationsQuerySync() {
  const ctx = useNotifications();
  const setItemsRef = useRef(ctx?.setItems);
  const setUnreadCountRef = useRef(ctx?.setUnreadCount);
  setItemsRef.current = ctx?.setItems;
  setUnreadCountRef.current = ctx?.setUnreadCount;

  const { data } = useQuery({
    queryKey: adminQueryKeys.notifications,
    queryFn: fetchNotifications,
    staleTime: 30_000,
    gcTime: 600_000,
    refetchOnWindowFocus: true,
  });

  useEffect(() => {
    if (data && setItemsRef.current && setUnreadCountRef.current) {
      const items = data.items.slice(0, 10).map((item) => ({
        id: item.id,
        title: item.title,
        message: item.message,
        timeLabel: item.timeLabel,
        isUnread: item.isUnread,
        ...(item.href && { href: item.href }),
      }));
      setItemsRef.current(items);
      setUnreadCountRef.current(data.unreadCount);
    }
  }, [data]);

  return null;
}
