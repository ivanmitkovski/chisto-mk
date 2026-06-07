'use client';

import { useCallback, useEffect, useState } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';
import { ADMIN_SEARCH_DEBOUNCE_MS } from '@/lib/utils';
import {
  isUsersSortKey,
  type UsersSortDir,
  type UsersSortKey,
} from '@/features/users/config/users-list-sort';

type UrlUpdates = {
  search?: string;
  role?: string;
  status?: string;
  page?: number;
  sort?: UsersSortKey;
  dir?: UsersSortDir;
};

export function useUsersListUrl() {
  const router = useRouter();
  const searchParams = useSearchParams();

  const search = searchParams.get('search') ?? '';
  const role = searchParams.get('role') ?? '';
  const status = searchParams.get('status') ?? '';
  const sortParam = searchParams.get('sort');
  const dirParam = searchParams.get('dir');
  const sort: UsersSortKey = isUsersSortKey(sortParam) ? sortParam : 'createdAt';
  const dir: UsersSortDir = dirParam === 'asc' ? 'asc' : 'desc';

  const [searchTerm, setSearchTerm] = useState(search);
  const [debouncedSearch, setDebouncedSearch] = useState(search);

  const buildUrl = useCallback(
    (updates: UrlUpdates) => {
      const sp = new URLSearchParams(searchParams.toString());
      if (updates.search !== undefined) {
        if (updates.search) sp.set('search', updates.search);
        else sp.delete('search');
      }
      if (updates.role !== undefined) {
        if (updates.role) sp.set('role', updates.role);
        else sp.delete('role');
      }
      if (updates.status !== undefined) {
        if (updates.status) sp.set('status', updates.status);
        else sp.delete('status');
      }
      if (updates.page !== undefined) {
        if (updates.page > 1) sp.set('page', String(updates.page));
        else sp.delete('page');
      }
      if (updates.sort !== undefined) {
        if (updates.sort !== 'createdAt') sp.set('sort', updates.sort);
        else sp.delete('sort');
      }
      if (updates.dir !== undefined) {
        if (updates.dir !== 'desc') sp.set('dir', updates.dir);
        else sp.delete('dir');
      }
      const q = sp.toString();
      return `/dashboard/users${q ? `?${q}` : ''}`;
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

  const handleRoleChange = (value: string) => {
    router.push(buildUrl({ role: value, page: 1 }));
  };

  const handleStatusChange = (value: string) => {
    router.push(buildUrl({ status: value, page: 1 }));
  };

  const handleSort = (key: string) => {
    const nextKey = isUsersSortKey(key) ? key : sort;
    const nextDir: UsersSortDir = sort === nextKey && dir === 'desc' ? 'asc' : 'desc';
    router.push(buildUrl({ sort: nextKey, dir: nextDir, page: 1 }));
  };

  const refresh = useCallback(() => {
    router.refresh();
  }, [router]);

  const page = Number(searchParams.get('page') ?? '1') || 1;

  return {
    search,
    page,
    searchTerm,
    setSearchTerm,
    debouncedSearch,
    role,
    status,
    sort,
    dir,
    buildUrl,
    handleRoleChange,
    handleStatusChange,
    handleSort,
    refresh,
    router,
  };
}
