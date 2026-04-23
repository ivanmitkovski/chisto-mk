'use client';

import { useEffect, useState } from 'react';
import {
  fetchEventScheduleConflict,
  type ConflictingEventInfo,
} from './event-schedule-conflict-client';

export function useScheduleConflictPreview(options: {
  siteId: string;
  /** ISO string or null to skip fetch */
  scheduledAtIso: string | null;
  endAtIso?: string | null;
  excludeEventId?: string;
  debounceMs?: number;
}): { hint: ConflictingEventInfo | null; checking: boolean } {
  const { siteId, scheduledAtIso, endAtIso, excludeEventId, debounceMs = 480 } = options;
  const [hint, setHint] = useState<ConflictingEventInfo | null>(null);
  const [checking, setChecking] = useState(false);

  useEffect(() => {
    if (!siteId || !scheduledAtIso) {
      setHint(null);
      return;
    }

    let cancelled = false;
    const timer = setTimeout(() => {
      void (async () => {
        setChecking(true);
        try {
          const res = await fetchEventScheduleConflict({
            siteId,
            scheduledAtIso,
            ...(endAtIso != null && endAtIso.trim() !== '' ? { endAtIso } : {}),
            ...(excludeEventId != null && excludeEventId !== '' ? { excludeEventId } : {}),
          });
          if (cancelled) {
            return;
          }
          if (res.hasConflict && res.conflictingEvent) {
            setHint(res.conflictingEvent);
          } else {
            setHint(null);
          }
        } catch {
          if (!cancelled) {
            setHint(null);
          }
        } finally {
          if (!cancelled) {
            setChecking(false);
          }
        }
      })();
    }, debounceMs);

    return () => {
      cancelled = true;
      clearTimeout(timer);
    };
  }, [siteId, scheduledAtIso, endAtIso, excludeEventId, debounceMs]);

  return { hint, checking };
}
