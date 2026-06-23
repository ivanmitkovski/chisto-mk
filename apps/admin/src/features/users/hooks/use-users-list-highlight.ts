'use client';

import { useEffect, useRef, useState } from 'react';
import { subscribeUserUpdatedSignal } from '@/lib/realtime';

const HIGHLIGHT_MS = 7000;

export function useUsersListHighlight() {
  const [highlightedUserIds, setHighlightedUserIds] = useState<Set<string>>(new Set());
  const highlightTimeoutsRef = useRef<Map<string, number>>(new Map());

  useEffect(() => {
    return subscribeUserUpdatedSignal(({ userId }) => {
      setHighlightedUserIds((prev) => {
        const next = new Set(prev);
        next.add(userId);
        const existing = highlightTimeoutsRef.current.get(userId);
        if (existing != null) window.clearTimeout(existing);
        const timeoutId = window.setTimeout(() => {
          setHighlightedUserIds((current) => {
            if (!current.has(userId)) return current;
            const updated = new Set(current);
            updated.delete(userId);
            return updated;
          });
          highlightTimeoutsRef.current.delete(userId);
        }, HIGHLIGHT_MS);
        highlightTimeoutsRef.current.set(userId, timeoutId);
        return next;
      });
    });
  }, []);

  useEffect(() => {
    return () => {
      for (const timeoutId of highlightTimeoutsRef.current.values()) {
        window.clearTimeout(timeoutId);
      }
      highlightTimeoutsRef.current.clear();
    };
  }, []);

  return { highlightedUserIds };
}
