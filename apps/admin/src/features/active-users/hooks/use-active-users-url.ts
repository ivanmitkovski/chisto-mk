'use client';

import { useCallback, useEffect, useState } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { ADMIN_SEARCH_DEBOUNCE_MS } from '@/lib/utils';
import { ACTIVE_USERS_PAGE_SIZE } from '../constants/active-users-filters';

type UrlUpdates = {
  search?: string;
  status?: string;
  platform?: string;
  page?: number;
  feedType?: string;
};

export function useActiveUsersUrl() {
  const router = useRouter();
  const searchParams = useSearchParams();

  const search = searchParams.get('search') ?? '';
  const status = searchParams.get('status') ?? '';
  const platform = searchParams.get('platform') ?? '';
  const feedType = searchParams.get('feedType') ?? '';
  const page = Math.max(1, Number(searchParams.get('page') ?? '1') || 1);

  const [searchTerm, setSearchTerm] = useState(search);
  const [debouncedSearch, setDebouncedSearch] = useState(search);

  const buildUrl = useCallback(
    (updates: UrlUpdates) => {
      const sp = new URLSearchParams(searchParams.toString());
      if (updates.search !== undefined) {
        if (updates.search) sp.set('search', updates.search);
        else sp.delete('search');
      }
      if (updates.status !== undefined) {
        if (updates.status) sp.set('status', updates.status);
        else sp.delete('status');
      }
      if (updates.platform !== undefined) {
        if (updates.platform) sp.set('platform', updates.platform);
        else sp.delete('platform');
      }
      if (updates.feedType !== undefined) {
        if (updates.feedType) sp.set('feedType', updates.feedType);
        else sp.delete('feedType');
      }
      if (updates.page !== undefined) {
        if (updates.page > 1) sp.set('page', String(updates.page));
        else sp.delete('page');
      }
      const q = sp.toString();
      return q ? `?${q}` : '';
    },
    [searchParams],
  );

  const pushUrl = useCallback(
    (updates: UrlUpdates) => {
      router.push(`/dashboard/active-users${buildUrl(updates)}`);
    },
    [router, buildUrl],
  );

  useEffect(() => {
    setSearchTerm(search);
    setDebouncedSearch(search);
  }, [search]);

  useEffect(() => {
    const timer = window.setTimeout(() => {
      if (debouncedSearch !== search) {
        pushUrl({ search: debouncedSearch, page: 1 });
      }
    }, ADMIN_SEARCH_DEBOUNCE_MS);
    return () => window.clearTimeout(timer);
  }, [debouncedSearch, search, pushUrl]);

  return {
    searchTerm,
    setSearchTerm,
    debouncedSearch,
    status,
    platform,
    feedType,
    page,
    limit: ACTIVE_USERS_PAGE_SIZE,
    setStatus: (value: string) => pushUrl({ status: value, page: 1 }),
    setPlatform: (value: string) => pushUrl({ platform: value, page: 1 }),
    setFeedType: (value: string) => pushUrl({ feedType: value }),
    setPage: (value: number) => pushUrl({ page: value }),
  };
}
