'use client';

import { useMemo, useState } from 'react';
import { useTranslations } from 'next-intl';
import { useQuery } from '@tanstack/react-query';
import {
  adminQueryKeys,
  fetchNotifications,
  type AdminNotificationItem,
  type FetchNotificationsParams,
} from '@/lib/api';
import { NotificationsCenter } from './notifications-center';
import type { AdminNotification } from '../types';
import { SectionState } from '@/components/ui';
import { Button } from '@/components/ui';
import { ApiConnectionError, ApiError } from '@/lib/api';

type FilterKey = 'all' | 'unread' | 'reports' | 'system' | 'analytics';

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

export function NotificationsDashboardPageClient() {
  const t = useTranslations('notifications');
  const tErrors = useTranslations('errors');
  const [filter, setFilter] = useState<FilterKey>('all');
  const [page, setPage] = useState(1);
  const queryParams = useMemo(() => toFetchParams(filter, page), [filter, page]);

  const { data, isPending, isError, error, refetch } = useQuery({
    queryKey: adminQueryKeys.notifications(queryParams),
    queryFn: () => fetchNotifications(queryParams),
    retry: 1,
  });

  function notificationsFetchErrorMessage(fetchError: unknown): string {
    if (fetchError instanceof ApiConnectionError) {
      return tErrors('couldNotReachApi');
    }
    if (fetchError instanceof ApiError) {
      if (fetchError.status === 401 || fetchError.status === 403) {
        return tErrors('sessionMissingOrExpired');
      }
      if (fetchError.status >= 500) {
        return tErrors('apiReturnedError');
      }
      return tErrors('couldNotLoadNotificationsHttp', { status: fetchError.status });
    }
    if (fetchError instanceof Error && fetchError.message === 'Not signed in') {
      return tErrors('notSignedIn');
    }
    return tErrors('unableToLoadNotifications');
  }

  if (isPending) {
    return <SectionState variant="loading-skeleton" message={t('loading')} skeletonLines={4} />;
  }

  if (isError) {
    return (
      <SectionState variant="error" message={notificationsFetchErrorMessage(error)}>
        <Button variant="outline" size="sm" onClick={() => void refetch()}>
          {t('retry')}
        </Button>
      </SectionState>
    );
  }

  if (!data.items.length && filter === 'all' && page === 1) {
    return <SectionState variant="empty" message={t('emptyDashboard')} />;
  }

  return (
    <NotificationsCenter
      items={mapToAdminNotifications(data.items)}
      unreadCount={data.unreadCount}
      total={data.meta.total}
      page={data.meta.page}
      limit={data.meta.limit}
      filter={filter}
      onFilterChange={(next) => {
        setFilter(next);
        setPage(1);
      }}
      onPageChange={setPage}
      onRefetch={() => void refetch()}
    />
  );
}

function toFetchParams(filter: FilterKey, page: number): FetchNotificationsParams {
  const base = { page, limit: 20 };
  if (filter === 'unread') return { ...base, onlyUnread: true };
  if (filter === 'reports' || filter === 'system' || filter === 'analytics') {
    return { ...base, category: filter };
  }
  return base;
}
