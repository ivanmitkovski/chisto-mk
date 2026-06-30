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
import { useServerSyncedState } from '@/features/admin-shell/hooks/use-server-synced-state';
import type {
  ActiveUserRow,
  ActiveUsersSummary,
  ActivityFeedItem,
  AdminAlertRule,
  RealtimeAnalytics,
} from '../data/active-users.types';
import {
  browserFetchActiveUsersList,
  browserFetchActivityFeed,
  browserFetchRealtime,
  browserFetchSummary,
  type ActiveUsersListFilters,
} from '../data/active-users-adapter.client';
import { FEED_PAGE_LIMIT, mergeFeedItems } from './merge-feed-items';
import { useDashboardSSE } from '@/features/dashboard-overview/context/dashboard-sse-context';

const POLL_MS = 12_000;
const REALTIME_POLL_MS = 20_000;
const LIST_DEBOUNCE_MS = 300;

export type ActiveUsersLoadErrors = {
  summary?: string;
  list?: string;
  feed?: string;
  realtime?: string;
};

type ActiveUsersLiveContextValue = {
  summary: ActiveUsersSummary | null;
  summaryError: string | null;
  rows: ActiveUserRow[];
  listTotal: number;
  listError: string | null;
  realtime: RealtimeAnalytics;
  realtimeError: string | null;
  feed: ActivityFeedItem[];
  feedTotal: number;
  feedError: string | null;
  feedType: string;
  alertRules: AdminAlertRule[];
  setAlertRules: (rules: AdminAlertRule[]) => void;
  highlightedAlertId: string | null;
  setHighlightedAlertId: (id: string | null) => void;
  hasMore: boolean;
  isLoadingMore: boolean;
  isRefreshing: boolean;
  lastUpdatedAt: number;
  refresh: () => void;
  loadMore: () => void;
  setFeedType: (type: string) => void;
  applySseSummary: (partial: Partial<ActiveUsersSummary>) => void;
  pushFeedItem: (item: ActivityFeedItem) => void;
};

const ActiveUsersLiveContext = createContext<ActiveUsersLiveContextValue | null>(null);

type ActiveUsersLiveProviderProps = {
  children: ReactNode;
  initialSummary: ActiveUsersSummary | null;
  initialRows: ActiveUserRow[];
  initialListTotal: number;
  initialRealtime: RealtimeAnalytics;
  initialFeedType: string;
  initialAlertRules: AdminAlertRule[];
  listFilters: ActiveUsersListFilters;
  loadErrors?: ActiveUsersLoadErrors;
};

export function ActiveUsersLiveProvider({
  children,
  initialSummary,
  initialRows,
  initialListTotal,
  initialRealtime,
  initialFeedType,
  initialAlertRules,
  listFilters,
  loadErrors = {},
}: ActiveUsersLiveProviderProps) {
  const sseCtx = useDashboardSSE();
  const sseConnected = sseCtx?.connected ?? false;
  const [summary, setSummary] = useState<ActiveUsersSummary | null>(initialSummary);
  const [summaryError, setSummaryError] = useState<string | null>(loadErrors.summary ?? null);
  const [rows, setRows] = useServerSyncedState(initialRows);
  const [listTotal, setListTotal] = useState(initialListTotal);
  const [listError, setListError] = useState<string | null>(loadErrors.list ?? null);
  const [realtime, setRealtime] = useState<RealtimeAnalytics>(initialRealtime);
  const [realtimeError, setRealtimeError] = useState<string | null>(loadErrors.realtime ?? null);
  const [feed, setFeed] = useState<ActivityFeedItem[]>([]);
  const [feedTotal, setFeedTotal] = useState(0);
  const [feedError, setFeedError] = useState<string | null>(loadErrors.feed ?? null);
  const [feedType, setFeedTypeState] = useState(initialFeedType);
  const [alertRules, setAlertRules] = useState(initialAlertRules);
  const [highlightedAlertId, setHighlightedAlertId] = useState<string | null>(null);
  const [isLoadingMore, setIsLoadingMore] = useState(false);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [lastUpdatedAt, setLastUpdatedAt] = useState(() => Date.now());

  const highestPageRef = useRef(0);
  const loadMoreInFlightRef = useRef(false);
  const listRefreshTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const listFiltersKey = JSON.stringify(listFilters);
  const skipInitialListFetchRef = useRef(initialRows.length > 0);

  const hasMore = feed.length < feedTotal;

  const fetchList = useCallback(async () => {
    try {
      const res = await browserFetchActiveUsersList(listFilters);
      setRows(res.rows);
      setListTotal(res.total);
      setListError(null);
    } catch {
      setListError('list');
    }
  }, [listFiltersKey, listFilters]);

  const fetchSummary = useCallback(async () => {
    try {
      const res = await browserFetchSummary();
      setSummary(res);
      setSummaryError(null);
    } catch {
      setSummaryError('summary');
    }
  }, []);

  const fetchRealtime = useCallback(async () => {
    try {
      const res = await browserFetchRealtime();
      setRealtime(res);
      setRealtimeError(null);
    } catch {
      setRealtimeError('realtime');
    }
  }, []);

  const fetchFeedFirstPage = useCallback(async (type: string) => {
    try {
      const res = await browserFetchActivityFeed(1, FEED_PAGE_LIMIT, type || undefined);
      setFeedTotal(res.total);
      setFeed((prev) => mergeFeedItems(prev, res.items));
      highestPageRef.current = Math.max(highestPageRef.current, 1);
      setFeedError(null);
    } catch {
      setFeedError('feed');
    }
  }, []);

  const refresh = useCallback(() => {
    setIsRefreshing(true);
    sseCtx?.touchLastUpdated();
    void Promise.all([
      fetchSummary(),
      fetchList(),
      fetchRealtime(),
      fetchFeedFirstPage(feedType),
    ]).finally(() => {
      setLastUpdatedAt(Date.now());
      setIsRefreshing(false);
    });
  }, [fetchSummary, fetchList, fetchRealtime, fetchFeedFirstPage, feedType, sseCtx]);

  const loadMore = useCallback(() => {
    if (loadMoreInFlightRef.current || feed.length >= feedTotal) return;
    loadMoreInFlightRef.current = true;
    setIsLoadingMore(true);
    const nextPage = highestPageRef.current + 1;
    void browserFetchActivityFeed(nextPage, FEED_PAGE_LIMIT, feedType || undefined)
      .then((res) => {
        setFeedTotal(res.total);
        setFeed((prev) => mergeFeedItems(prev, res.items));
        highestPageRef.current = nextPage;
      })
      .catch(() => setFeedError('feed'))
      .finally(() => {
        loadMoreInFlightRef.current = false;
        setIsLoadingMore(false);
      });
  }, [feed.length, feedTotal, feedType]);

  const applySseSummary = useCallback((partial: Partial<ActiveUsersSummary>) => {
    setSummary((prev) => (prev ? { ...prev, ...partial } : prev));
    if (listRefreshTimerRef.current) clearTimeout(listRefreshTimerRef.current);
    listRefreshTimerRef.current = setTimeout(() => {
      void fetchList();
    }, LIST_DEBOUNCE_MS);
  }, [fetchList]);

  const pushFeedItem = useCallback((item: ActivityFeedItem) => {
    setFeed((prev) => mergeFeedItems([item], prev));
  }, []);

  const setFeedType = useCallback((type: string) => {
    setFeedTypeState(type);
    setFeed([]);
    highestPageRef.current = 0;
    void fetchFeedFirstPage(type);
  }, [fetchFeedFirstPage]);

  useEffect(() => {
    setListTotal(initialListTotal);
  }, [initialListTotal, listFiltersKey]);

  useEffect(() => {
    if (skipInitialListFetchRef.current) {
      skipInitialListFetchRef.current = false;
      return;
    }
    void fetchList();
  }, [fetchList]);

  useEffect(() => {
    setFeed([]);
    highestPageRef.current = 0;
    void fetchFeedFirstPage(feedType);
  }, [feedType, fetchFeedFirstPage]);

  useEffect(() => {
    if (sseConnected) return undefined;

    const pollId = window.setInterval(() => {
      if (!document.hidden) {
        void fetchSummary();
        void fetchList();
        void browserFetchActivityFeed(1, FEED_PAGE_LIMIT, feedType || undefined)
          .then((res) => {
            setFeedTotal(res.total);
            setFeed((prev) => mergeFeedItems(prev, res.items));
          })
          .catch(() => setFeedError('feed'));
        setLastUpdatedAt(Date.now());
      }
    }, POLL_MS);
    const realtimeId = window.setInterval(() => {
      if (!document.hidden) void fetchRealtime();
    }, REALTIME_POLL_MS);
    return () => {
      window.clearInterval(pollId);
      window.clearInterval(realtimeId);
      if (listRefreshTimerRef.current) clearTimeout(listRefreshTimerRef.current);
    };
  }, [fetchSummary, fetchList, fetchRealtime, feedType, sseConnected]);

  const value = useMemo(
    () => ({
      summary,
      summaryError,
      rows,
      listTotal,
      listError,
      realtime,
      realtimeError: realtimeError,
      feed,
      feedTotal,
      feedError,
      feedType,
      alertRules,
      setAlertRules,
      highlightedAlertId,
      setHighlightedAlertId,
      hasMore,
      isLoadingMore,
      isRefreshing,
      lastUpdatedAt,
      refresh,
      loadMore,
      setFeedType,
      applySseSummary,
      pushFeedItem,
    }),
    [
      summary,
      summaryError,
      rows,
      listTotal,
      listError,
      realtime,
      realtimeError,
      feed,
      feedTotal,
      feedError,
      feedType,
      alertRules,
      highlightedAlertId,
      hasMore,
      isLoadingMore,
      isRefreshing,
      lastUpdatedAt,
      refresh,
      loadMore,
      setFeedType,
      applySseSummary,
      pushFeedItem,
    ],
  );

  return <ActiveUsersLiveContext.Provider value={value}>{children}</ActiveUsersLiveContext.Provider>;
}

export function useActiveUsersLive() {
  const ctx = useContext(ActiveUsersLiveContext);
  if (!ctx) throw new Error('useActiveUsersLive must be used within ActiveUsersLiveProvider');
  return ctx;
}

export function useActiveUsersLiveOptional() {
  return useContext(ActiveUsersLiveContext);
}
