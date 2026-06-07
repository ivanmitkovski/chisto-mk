'use client';

import { useCallback, useEffect, useState } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { ADMIN_SEARCH_DEBOUNCE_MS } from '@/lib/utils';

type UrlUpdates = {
  status?: string;
  page?: number;
  search?: string;
};

export function useSitesListUrl() {
  const router = useRouter();
  const searchParams = useSearchParams();

  const status = searchParams.get('status') ?? '';
  const search = searchParams.get('search') ?? '';

  const [searchTerm, setSearchTerm] = useState(search);
  const [debouncedSearch, setDebouncedSearch] = useState(search);

  const buildUrl = useCallback(
    (updates: UrlUpdates) => {
      const sp = new URLSearchParams(searchParams.toString());
      if (updates.status !== undefined) {
        if (updates.status) sp.set('status', updates.status);
        else sp.delete('status');
      }
      if (updates.page !== undefined) {
        if (updates.page > 1) sp.set('page', String(updates.page));
        else sp.delete('page');
      }
      if (updates.search !== undefined) {
        if (updates.search) sp.set('search', updates.search);
        else sp.delete('search');
      }
      const q = sp.toString();
      return `/dashboard/sites${q ? `?${q}` : ''}`;
    },
    [searchParams],
  );

  useEffect(() => {
    setSearchTerm(search);
    setDebouncedSearch(search);
  }, [search]);

  useEffect(() => {
    const timer = window.setTimeout(() => setDebouncedSearch(searchTerm), ADMIN_SEARCH_DEBOUNCE_MS);
    return () => window.clearTimeout(timer);
  }, [searchTerm]);

  useEffect(() => {
    if (debouncedSearch.trim() === search.trim()) return;
    router.push(buildUrl({ search: debouncedSearch.trim(), page: 1 }));
  }, [buildUrl, debouncedSearch, router, search]);

  const handleStatusChange = (value: string) => {
    router.push(buildUrl({ status: value, page: 1 }));
  };

  const refresh = useCallback(() => {
    router.refresh();
  }, [router]);

  const page = Number(searchParams.get('page') ?? '1') || 1;

  return {
    status,
    page,
    searchTerm,
    setSearchTerm,
    buildUrl,
    handleStatusChange,
    refresh,
    router,
  };
}
