'use client';

import { createContext, useCallback, useContext, useState, type ReactNode } from 'react';
import { adminBrowserFetch } from '@/lib/admin-browser-api';
import type { TopBarNotification } from '@/features/admin-shell/types/top-bar';

type NotificationsContextValue = {
  items: TopBarNotification[];
  unreadCount: number;
  markOneRead: (id: string) => Promise<void>;
  markAllRead: () => Promise<void>;
  /** Sync top bar after a read elsewhere (e.g. full notifications page) without a second API call. */
  applyNotificationRead: (id: string, wasUnread: boolean) => void;
  setItems: (items: TopBarNotification[]) => void;
  setUnreadCount: (count: number) => void;
};

const NotificationsContext = createContext<NotificationsContextValue | null>(null);

export function useNotifications(): NotificationsContextValue | null {
  return useContext(NotificationsContext);
}

type NotificationsProviderProps = {
  children: ReactNode;
  initialItems: TopBarNotification[];
  initialUnreadCount: number;
};

function toTopBarNotification(item: {
  id: string;
  title: string;
  message: string;
  timeLabel: string;
  createdAt?: string;
  isUnread: boolean;
  href?: string;
}): TopBarNotification {
  const base: TopBarNotification = {
    id: item.id,
    title: item.title,
    message: item.message,
    timeLabel: item.timeLabel,
    isUnread: item.isUnread,
    ...(item.createdAt && { createdAt: item.createdAt }),
  };
  return item.href ? { ...base, href: item.href } : base;
}

export function NotificationsProvider({
  children,
  initialItems,
  initialUnreadCount,
}: NotificationsProviderProps) {
  const [items, setItemsState] = useState<TopBarNotification[]>(() =>
    initialItems.map(toTopBarNotification),
  );
  const [unreadCount, setUnreadCount] = useState(initialUnreadCount);

  // Live list comes from NotificationsQuerySync + mutations. Do not reset from RSC props on
  // router.refresh() — server getAdminNotifications often fails while client fetch succeeds,
  // which would wipe the bell (see plan: notifications persistence).

  const setItems = useCallback((next: TopBarNotification[]) => {
    setItemsState(next);
    setUnreadCount(next.filter((n) => n.isUnread).length);
  }, []);

  const markOneRead = useCallback(async (id: string) => {
    const previous = items;
    const next = items.map((n) =>
      n.id === id && n.isUnread ? { ...n, isUnread: false } : n,
    );
    setItemsState(next);
    setUnreadCount(next.filter((n) => n.isUnread).length);
    try {
      await adminBrowserFetch(`/admin/notifications/${encodeURIComponent(id)}/read`, {
        method: 'PATCH',
      });
    } catch {
      setItemsState(previous);
      setUnreadCount(previous.filter((n) => n.isUnread).length);
    }
  }, [items]);

  const markAllRead = useCallback(async () => {
    const previous = items;
    setItemsState((prev) => prev.map((n) => ({ ...n, isUnread: false })));
    setUnreadCount(0);
    try {
      await adminBrowserFetch('/admin/notifications/read-all', { method: 'PATCH' });
    } catch {
      setItemsState(previous);
      setUnreadCount(previous.filter((n) => n.isUnread).length);
    }
  }, [items]);

  const applyNotificationRead = useCallback((id: string, wasUnread: boolean) => {
    setItemsState((prev) =>
      prev.map((n) => (n.id === id ? { ...n, isUnread: false } : n)),
    );
    if (wasUnread) {
      setUnreadCount((c) => Math.max(0, c - 1));
    }
  }, []);

  const value: NotificationsContextValue = {
    items,
    unreadCount,
    markOneRead,
    markAllRead,
    applyNotificationRead,
    setItems,
    setUnreadCount,
  };

  return (
    <NotificationsContext.Provider value={value}>
      {children}
    </NotificationsContext.Provider>
  );
}
