'use client';

import { createContext, useContext, useEffect, useMemo, type ReactNode } from 'react';
import { useWorkspaceRefresh } from '@/features/admin-shell/hooks/use-workspace-refresh';
import { adminBrowserFetch } from '@/lib/api';
import { OPS_POLL_INTERVAL_MS } from '../config';
import { useMetricHistory } from '../hooks/use-metric-history';

type OperationsLiveContextValue = {
  refresh: () => void;
  isRefreshing: boolean;
  getSeries: ReturnType<typeof useMetricHistory>['getSeries'];
};

const OperationsLiveContext = createContext<OperationsLiveContextValue | null>(null);

export function OperationsLiveProvider({ children }: { children: ReactNode }) {
  const { refresh, isRefreshing } = useWorkspaceRefresh();
  const { recordSnapshot, getSeries } = useMetricHistory();

  useEffect(() => {
    if (typeof document === 'undefined') return undefined;

    const sampleMetrics = async () => {
      try {
        const snapshot = await adminBrowserFetch<Awaited<ReturnType<typeof import('../data/operations-adapter').fetchOperationsMetricsSnapshot>>>(
          '/admin/operations/metrics-snapshot',
          { method: 'GET' },
        );
        recordSnapshot(snapshot);
      } catch {
        /* keep last history on transient failures */
      }
    };

    const tick = () => {
      if (document.hidden) return;
      refresh();
      void sampleMetrics();
    };

    void sampleMetrics();
    const id = window.setInterval(tick, OPS_POLL_INTERVAL_MS);
    return () => window.clearInterval(id);
  }, [refresh, recordSnapshot]);

  const value = useMemo(
    () => ({
      refresh,
      isRefreshing,
      getSeries,
    }),
    [refresh, isRefreshing, getSeries],
  );

  return <OperationsLiveContext.Provider value={value}>{children}</OperationsLiveContext.Provider>;
}

export function useOperationsLive() {
  const ctx = useContext(OperationsLiveContext);
  if (!ctx) {
    throw new Error('useOperationsLive must be used within OperationsLiveProvider');
  }
  return ctx;
}
