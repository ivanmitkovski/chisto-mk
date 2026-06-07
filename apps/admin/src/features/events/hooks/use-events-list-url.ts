'use client';

import { useEffect, useState } from 'react';
import { useRouter, useSearchParams } from 'next/navigation';

type UrlUpdates = {
  status?: string;
  moderationStatus?: string;
  page?: number;
  q?: string;
};

export function useEventsListUrl() {
  const router = useRouter();
  const searchParams = useSearchParams();

  const status = searchParams.get('status') ?? '';
  const moderationStatus = searchParams.get('moderationStatus') ?? '';
  const listQuery = searchParams.get('q') ?? '';

  const [searchDraft, setSearchDraft] = useState(listQuery);

  useEffect(() => {
    setSearchDraft(listQuery);
  }, [listQuery]);

  function buildUrl(updates: UrlUpdates) {
    const sp = new URLSearchParams(searchParams.toString());
    if (updates.status !== undefined) {
      if (updates.status) sp.set('status', updates.status);
      else sp.delete('status');
    }
    if (updates.moderationStatus !== undefined) {
      if (updates.moderationStatus) sp.set('moderationStatus', updates.moderationStatus);
      else sp.delete('moderationStatus');
    }
    if (updates.page !== undefined) {
      if (updates.page > 1) sp.set('page', String(updates.page));
      else sp.delete('page');
    }
    if (updates.q !== undefined) {
      const t = updates.q.trim();
      if (t.length >= 2) sp.set('q', t);
      else sp.delete('q');
    }
    const qs = sp.toString();
    return `/dashboard/events${qs ? `?${qs}` : ''}`;
  }

  function handleStatusChange(value: string) {
    router.push(buildUrl({ status: value, page: 1 }));
  }

  function handleModerationChange(value: string) {
    router.push(buildUrl({ moderationStatus: value, page: 1 }));
  }

  function applySearchToUrl() {
    router.push(buildUrl({ q: searchDraft, page: 1 }));
  }

  function refresh() {
    router.refresh();
  }

  return {
    status,
    moderationStatus,
    listQuery,
    searchDraft,
    setSearchDraft,
    buildUrl,
    handleStatusChange,
    handleModerationChange,
    applySearchToUrl,
    refresh,
    router,
  };
}
