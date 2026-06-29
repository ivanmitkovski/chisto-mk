'use client';

import { useCallback, useEffect, useRef, useState } from 'react';
import type { NewsLocale } from '../news-api-types';
import type { NewsFormLocale } from '../types';

type UpdateAltFn = (
  mediaId: string,
  altText: Partial<Record<NewsLocale, string>>,
) => Promise<void>;

type UseNewsAltTextSaveOptions = {
  onError?: (error: unknown) => void;
};

export function useNewsAltTextSave(
  updateMediaAlt: UpdateAltFn,
  options?: UseNewsAltTextSaveOptions,
) {
  const timersRef = useRef<Map<string, ReturnType<typeof setTimeout>>>(new Map());
  const pendingRef = useRef<Map<string, Partial<Record<NewsLocale, string>>>>(new Map());
  const inFlightRef = useRef<Promise<void> | null>(null);
  const [altPending, setAltPending] = useState(false);

  const syncPendingState = useCallback(() => {
    setAltPending(pendingRef.current.size > 0 || timersRef.current.size > 0 || inFlightRef.current !== null);
  }, []);

  const flushAltSaves = useCallback(async () => {
    for (const timer of timersRef.current.values()) {
      clearTimeout(timer);
    }
    timersRef.current.clear();

    const entries = [...pendingRef.current.entries()];
    pendingRef.current.clear();
    if (entries.length === 0 && !inFlightRef.current) {
      syncPendingState();
      return;
    }

    const run = async () => {
      if (inFlightRef.current) await inFlightRef.current;
      for (const [mediaId, altText] of entries) {
        try {
          await updateMediaAlt(mediaId, altText);
        } catch (error) {
          options?.onError?.(error);
          throw error;
        }
      }
    };

    const promise = run()
      .finally(() => {
        if (inFlightRef.current === promise) {
          inFlightRef.current = null;
        }
        syncPendingState();
      });
    inFlightRef.current = promise;
    syncPendingState();
    await promise;
  }, [options, syncPendingState, updateMediaAlt]);

  const scheduleAltSave = useCallback(
    (mediaId: string, altLocale: NewsFormLocale, nextAlt: Partial<Record<NewsLocale, string>>) => {
      pendingRef.current.set(mediaId, nextAlt);
      const key = `${mediaId}:${altLocale}`;
      const existing = timersRef.current.get(key);
      if (existing) clearTimeout(existing);
      timersRef.current.set(
        key,
        setTimeout(() => {
          timersRef.current.delete(key);
          void flushAltSaves();
        }, 450),
      );
      syncPendingState();
    },
    [flushAltSaves, syncPendingState],
  );

  useEffect(() => {
    return () => {
      for (const timer of timersRef.current.values()) {
        clearTimeout(timer);
      }
    };
  }, []);

  return { scheduleAltSave, flushAltSaves, altPending };
}
