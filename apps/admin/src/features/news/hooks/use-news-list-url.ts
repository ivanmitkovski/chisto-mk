'use client';

import { useCallback, useEffect, useMemo, useState } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { ADMIN_SEARCH_DEBOUNCE_MS } from '@/lib/utils';
import type { NewsSortOption } from '../config/news-list-filters';

type UrlUpdates = {
  status?: string;
  category?: string;
  page?: number;
  q?: string;
  sort?: NewsSortOption | '';
};

export function useNewsListUrl() {
  const router = useRouter();
  const searchParams = useSearchParams();

  const status = searchParams.get('status') ?? '';
  const category = searchParams.get('category') ?? '';
  const listQuery = searchParams.get('q') ?? '';
  const sort = (searchParams.get('sort') ?? 'publishedAt') as NewsSortOption;
  const page = Math.max(1, Number.parseInt(searchParams.get('page') ?? '1', 10) || 1);

  const [searchDraft, setSearchDraft] = useState(listQuery);
  const [debouncedSearch, setDebouncedSearch] = useState(listQuery);

  useEffect(() => {
    setSearchDraft(listQuery);
    setDebouncedSearch(listQuery);
  }, [listQuery]);

  useEffect(() => {
    const timer = window.setTimeout(() => setDebouncedSearch(searchDraft), ADMIN_SEARCH_DEBOUNCE_MS);
    return () => window.clearTimeout(timer);
  }, [searchDraft]);

  const buildUrl = useCallback(
    (updates: UrlUpdates) => {
      const sp = new URLSearchParams(searchParams.toString());
      if (updates.status !== undefined) {
        if (updates.status) sp.set('status', updates.status);
        else sp.delete('status');
      }
      if (updates.category !== undefined) {
        if (updates.category) sp.set('category', updates.category);
        else sp.delete('category');
      }
      if (updates.page !== undefined) {
        if (updates.page > 1) sp.set('page', String(updates.page));
        else sp.delete('page');
      }
      if (updates.q !== undefined) {
        const t = updates.q.trim();
        if (t.length >= 1) sp.set('q', t);
        else sp.delete('q');
      }
      if (updates.sort !== undefined) {
        if (updates.sort && updates.sort !== 'publishedAt') sp.set('sort', updates.sort);
        else sp.delete('sort');
      }
      const qs = sp.toString();
      return `/dashboard/news${qs ? `?${qs}` : ''}`;
    },
    [searchParams],
  );

  useEffect(() => {
    if (debouncedSearch.trim() === listQuery.trim()) return;
    router.push(buildUrl({ q: debouncedSearch.trim(), page: 1 }));
  }, [buildUrl, debouncedSearch, listQuery, router]);

  function handleStatusChange(value: string) {
    router.push(buildUrl({ status: value, page: 1 }));
  }

  function handleCategoryChange(value: string) {
    router.push(buildUrl({ category: value, page: 1 }));
  }

  function handleSortChange(value: NewsSortOption) {
    router.push(buildUrl({ sort: value, page: 1 }));
  }

  function applySearchToUrl() {
    router.push(buildUrl({ q: searchDraft, page: 1 }));
  }

  function clearSearch() {
    setSearchDraft('');
  }

  function clearAllFilters() {
    router.push(buildUrl({ status: '', category: '', q: '', page: 1 }));
  }

  function goToPage(nextPage: number) {
    router.push(buildUrl({ page: nextPage }));
  }

  function refresh() {
    router.refresh();
  }

  const hasActiveFilters = useMemo(
    () => Boolean(status || category || listQuery.trim()),
    [category, listQuery, status],
  );

  return {
    status,
    category,
    listQuery,
    debouncedSearch,
    sort,
    page,
    searchDraft,
    setSearchDraft,
    buildUrl,
    handleStatusChange,
    handleCategoryChange,
    handleSortChange,
    applySearchToUrl,
    clearSearch,
    clearAllFilters,
    goToPage,
    refresh,
    router,
    hasActiveFilters,
  };
}
