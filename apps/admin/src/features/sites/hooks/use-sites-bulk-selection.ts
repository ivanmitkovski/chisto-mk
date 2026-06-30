'use client';

import { useEffect, useRef, useState } from 'react';
import type { SiteRow } from '@/features/sites/data/sites-adapter';

export function useSitesBulkSelection(data: SiteRow[], selectionKey: string) {
  const [selectedIds, setSelectedIds] = useState<Set<string>>(new Set());
  const selectAllRef = useRef<HTMLInputElement | null>(null);

  const toggleSelection = (id: string) => {
    setSelectedIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  };

  const toggleAll = () => {
    if (selectedIds.size === data.length) {
      setSelectedIds(new Set());
    } else {
      setSelectedIds(new Set(data.map((s) => s.id)));
    }
  };

  const clearSelection = () => setSelectedIds(new Set());

  const allSelected = data.length > 0 && selectedIds.size === data.length;
  const someSelected = selectedIds.size > 0;

  useEffect(() => {
    setSelectedIds(new Set());
  }, [selectionKey]);

  useEffect(() => {
    const el = selectAllRef.current;
    if (el) el.indeterminate = someSelected && !allSelected;
  }, [someSelected, allSelected]);

  return {
    selectedIds,
    selectAllRef,
    toggleSelection,
    toggleAll,
    clearSelection,
    allSelected,
    someSelected,
  };
}
