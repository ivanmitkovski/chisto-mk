'use client';

import { useEffect, useRef, useState } from 'react';
import { subscribeNewReportSignal } from '@/lib/realtime';
import type { ReportRow } from '@/features/reports/types';

const HIGHLIGHT_MS = 7000;

export function useReportsListHighlight(reports: ReportRow[]) {
  const [highlightedReportIds, setHighlightedReportIds] = useState<Set<string>>(new Set());
  const seenReportIdsRef = useRef<Set<string>>(new Set());
  const highlightTimeoutsRef = useRef<Map<string, number>>(new Map());
  const signaledReportIdRef = useRef<string | null>(null);

  useEffect(() => {
    return subscribeNewReportSignal(({ reportId }) => {
      signaledReportIdRef.current = reportId;
    });
  }, []);

  useEffect(() => {
    const currentIds = new Set(reports.map((r) => r.id));

    if (seenReportIdsRef.current.size === 0) {
      seenReportIdsRef.current = currentIds;
      return;
    }

    const newlySeenIds = reports
      .map((r) => r.id)
      .filter((id) => !seenReportIdsRef.current.has(id));

    const signaledId = signaledReportIdRef.current;
    if (signaledId && currentIds.has(signaledId) && !newlySeenIds.includes(signaledId)) {
      newlySeenIds.unshift(signaledId);
    }

    if (newlySeenIds.length > 0) {
      setHighlightedReportIds((prev) => {
        const next = new Set(prev);
        for (const id of newlySeenIds) {
          next.add(id);
          const existing = highlightTimeoutsRef.current.get(id);
          if (existing != null) window.clearTimeout(existing);
          const timeoutId = window.setTimeout(() => {
            setHighlightedReportIds((current) => {
              if (!current.has(id)) return current;
              const updated = new Set(current);
              updated.delete(id);
              return updated;
            });
            highlightTimeoutsRef.current.delete(id);
          }, HIGHLIGHT_MS);
          highlightTimeoutsRef.current.set(id, timeoutId);
        }
        return next;
      });
    }

    seenReportIdsRef.current = currentIds;
  }, [reports]);

  useEffect(() => {
    return () => {
      for (const timeoutId of highlightTimeoutsRef.current.values()) {
        window.clearTimeout(timeoutId);
      }
      highlightTimeoutsRef.current.clear();
    };
  }, []);

  return { highlightedReportIds };
}
