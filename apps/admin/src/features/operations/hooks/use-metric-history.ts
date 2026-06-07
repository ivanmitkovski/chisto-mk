'use client';

import { useCallback, useEffect, useMemo, useState } from 'react';
import {
  METRIC_HISTORY_KEYS,
  METRIC_HISTORY_MAX_POINTS,
  METRIC_HISTORY_STORAGE_KEY,
  type MetricHistoryKey,
} from '../config';

export type MetricHistoryPoint = { t: number; v: number };
export type MetricHistoryStore = Record<MetricHistoryKey, MetricHistoryPoint[]>;

type MetricsSnapshotPayload = {
  pushSendsSuccess: number;
  pushSendsFailure: number;
  pushQueueDepth: number;
  pushDeadLetterCount: number;
  mapOutboxPending: number;
  requestsFailed: number;
  emailQueueDepth: number;
  capturedAt: string;
};

function emptyStore(): MetricHistoryStore {
  return METRIC_HISTORY_KEYS.reduce((acc, key) => {
    acc[key] = [];
    return acc;
  }, {} as MetricHistoryStore);
}

function readStore(): MetricHistoryStore {
  if (typeof window === 'undefined') return emptyStore();
  try {
    const raw = window.sessionStorage.getItem(METRIC_HISTORY_STORAGE_KEY);
    if (!raw) return emptyStore();
    const parsed = JSON.parse(raw) as Partial<MetricHistoryStore>;
    const store = emptyStore();
    for (const key of METRIC_HISTORY_KEYS) {
      store[key] = Array.isArray(parsed[key]) ? parsed[key] : [];
    }
    return store;
  } catch {
    return emptyStore();
  }
}

function writeStore(store: MetricHistoryStore): void {
  if (typeof window === 'undefined') return;
  try {
    window.sessionStorage.setItem(METRIC_HISTORY_STORAGE_KEY, JSON.stringify(store));
  } catch {
    /* ignore quota errors */
  }
}

function appendPoint(series: MetricHistoryPoint[], value: number, at = Date.now()): MetricHistoryPoint[] {
  const next = [...series, { t: at, v: value }];
  if (next.length <= METRIC_HISTORY_MAX_POINTS) return next;
  return next.slice(next.length - METRIC_HISTORY_MAX_POINTS);
}

export function useMetricHistory() {
  const [store, setStore] = useState<MetricHistoryStore>(() => emptyStore());

  useEffect(() => {
    setStore(readStore());
  }, []);

  const recordSnapshot = useCallback((snapshot: MetricsSnapshotPayload) => {
    const at = Date.parse(snapshot.capturedAt) || Date.now();
    setStore((prev) => {
      const next: MetricHistoryStore = { ...prev };
      next.pushSendsSuccess = appendPoint(prev.pushSendsSuccess, snapshot.pushSendsSuccess, at);
      next.pushSendsFailure = appendPoint(prev.pushSendsFailure, snapshot.pushSendsFailure, at);
      next.pushQueueDepth = appendPoint(prev.pushQueueDepth, snapshot.pushQueueDepth, at);
      next.pushDeadLetterCount = appendPoint(prev.pushDeadLetterCount, snapshot.pushDeadLetterCount, at);
      next.mapOutboxPending = appendPoint(prev.mapOutboxPending, snapshot.mapOutboxPending, at);
      next.requestsFailed = appendPoint(prev.requestsFailed, snapshot.requestsFailed, at);
      next.emailQueueDepth = appendPoint(prev.emailQueueDepth, snapshot.emailQueueDepth, at);
      writeStore(next);
      return next;
    });
  }, []);

  const getSeries = useCallback(
    (key: MetricHistoryKey) => store[key] ?? [],
    [store],
  );

  return useMemo(
    () => ({
      store,
      recordSnapshot,
      getSeries,
    }),
    [store, recordSnapshot, getSeries],
  );
}
