'use client';

import { useCallback, useMemo, useState } from 'react';
import { useNotifications } from '@/features/notifications/context/notifications-context';
import type { TopBarNotification } from '../types/top-bar';

type UseTopBarNotificationsOptions = {
  initialNotifications?: TopBarNotification[];
};

export function useTopBarNotifications({ initialNotifications = [] }: UseTopBarNotificationsOptions = {}) {
  const notificationsContext = useNotifications();
  const [localNotifications, setLocalNotifications] = useState<TopBarNotification[]>(() =>
    initialNotifications.map((n) => ({ ...n })),
  );

  const notifications = notificationsContext?.items ?? localNotifications;
  const unreadNotificationsCount =
    notificationsContext?.unreadCount ?? notifications.filter((n) => n.isUnread).length;

  const markAllNotificationsRead = useCallback(() => {
    if (notificationsContext) {
      void notificationsContext.markAllRead();
    } else {
      setLocalNotifications((prev) => prev.map((n) => (n.isUnread ? { ...n, isUnread: false } : n)));
    }
  }, [notificationsContext]);

  const markNotificationRead = useCallback(
    (id: string) => {
      if (notificationsContext) {
        void notificationsContext.markOneRead(id);
      } else {
        setLocalNotifications((prev) =>
          prev.map((n) => (n.id === id && n.isUnread ? { ...n, isUnread: false } : n)),
        );
      }
    },
    [notificationsContext],
  );

  return useMemo(
    () => ({
      notifications,
      unreadNotificationsCount,
      markAllNotificationsRead,
      markNotificationRead,
    }),
    [markAllNotificationsRead, markNotificationRead, notifications, unreadNotificationsCount],
  );
}
