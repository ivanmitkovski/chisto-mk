'use client';

import { useCallback, useEffect, useState } from 'react';
import type { CleanupEventRow } from '@/features/events/data/events-adapter';

export function useEventsBulkSelection(
  data: CleanupEventRow[],
  moderationStatus: string,
  canWriteCleanupEvents: boolean,
) {
  const [selectedIds, setSelectedIds] = useState<Set<string>>(() => new Set());

  useEffect(() => {
    setSelectedIds(new Set());
  }, [data, moderationStatus]);

  const toggleRowSelected = useCallback((id: string) => {
    setSelectedIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  }, []);

  const selectAllOnPage = useCallback(() => {
    setSelectedIds(new Set(data.map((e) => e.id)));
  }, [data]);

  const clearSelection = useCallback(() => {
    setSelectedIds(new Set());
  }, []);

  const showModerationBulk = moderationStatus === 'PENDING' && canWriteCleanupEvents;

  return {
    selectedIds,
    toggleRowSelected,
    selectAllOnPage,
    clearSelection,
    showModerationBulk,
  };
}
