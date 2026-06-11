'use client';

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
  type ReactNode,
} from 'react';
import type { ActiveUsersSummary, ActivityFeedItem } from '../data/active-users.types';
import { browserFetchActivityFeed, browserFetchSummary } from '../data/active-users-adapter.client';
import { FEED_PAGE_LIMIT, mergeFeedItems } from './merge-feed-items';

const POLL_MS = 12_000;

type ActiveUsersLiveContextValue = {
  summary: ActiveUsersSummary | null;
  feed: ActivityFeedItem[];
  total: number;
  hasMore: boolean;
  isLoadingMore: boolean;
  refresh: () => void;
  loadMore: () => void;
  applySseSummary: (partial: Partial<ActiveUsersSummary>) => void;
  pushFeedItem: (item: ActivityFeedItem) => void;
};

const ActiveUsersLiveContext = createContext<ActiveUsersLiveContextValue | null>(null);

export function ActiveUsersLiveProvider({
  children,
  initialSummary,
}: {
  children: ReactNode;
  initialSummary: ActiveUsersSummary | null;
}) {
  const [summary, setSummary] = useState<ActiveUsersSummary | null>(initialSummary);
  const [feed, setFeed] = useState<ActivityFeedItem[]>([]);
  const [total, setTotal] = useState(0);
  const [isLoadingMore, setIsLoadingMore] = useState(false);
  const highestPageRef = useRef(0);
  const loadMoreInFlightRef = useRef(false);

  const hasMore = feed.length < total;

  const refresh = useCallback(() => {
    void browserFetchSummary().then(setSummary).catch(() => {});
    void browserFetchActivityFeed(1, FEED_PAGE_LIMIT)
      .then((res) => {
        setTotal(res.total);
        setFeed((prev) => mergeFeedItems(prev, res.items));
        highestPageRef.current = Math.max(highestPageRef.current, 1);
      })
      .catch(() => {});
  }, []);

  const loadMore = useCallback(() => {
    if (loadMoreInFlightRef.current || feed.length >= total) return;
    loadMoreInFlightRef.current = true;
    setIsLoadingMore(true);
    const nextPage = highestPageRef.current + 1;
    void browserFetchActivityFeed(nextPage, FEED_PAGE_LIMIT)
      .then((res) => {
        setTotal(res.total);
        setFeed((prev) => mergeFeedItems(prev, res.items));
        highestPageRef.current = nextPage;
      })
      .catch(() => {})
      .finally(() => {
        loadMoreInFlightRef.current = false;
        setIsLoadingMore(false);
      });
  }, [feed.length, total]);

  const applySseSummary = useCallback((partial: Partial<ActiveUsersSummary>) => {
    setSummary((prev) => (prev ? { ...prev, ...partial } : prev));
  }, []);

  const pushFeedItem = useCallback((item: ActivityFeedItem) => {
    setFeed((prev) => mergeFeedItems([item], prev));
  }, []);

  useEffect(() => {
    refresh();
    const id = window.setInterval(() => {
      if (!document.hidden) refresh();
    }, POLL_MS);
    return () => window.clearInterval(id);
  }, [refresh]);

  const value = useMemo(
    () => ({
      summary,
      feed,
      total,
      hasMore,
      isLoadingMore,
      refresh,
      loadMore,
      applySseSummary,
      pushFeedItem,
    }),
    [summary, feed, total, hasMore, isLoadingMore, refresh, loadMore, applySseSummary, pushFeedItem],
  );

  return <ActiveUsersLiveContext.Provider value={value}>{children}</ActiveUsersLiveContext.Provider>;
}

export function useActiveUsersLive() {
  const ctx = useContext(ActiveUsersLiveContext);
  if (!ctx) throw new Error('useActiveUsersLive must be used within ActiveUsersLiveProvider');
  return ctx;
}
