'use client';

import { useEffect, useRef, useState } from 'react';
import { useTranslations } from 'next-intl';
import { validateNewsPostForm } from '../lib/news-post-policy';
import type { NewsPostFormValues } from '../types';

type AutosaveStatus = 'idle' | 'pending' | 'saving' | 'saved' | 'error';

type UseNewsAutosaveOptions = {
  dirty: boolean;
  readOnly: boolean;
  values: NewsPostFormValues;
  save: (options?: { silent?: boolean }) => Promise<boolean>;
  debounceMs?: number;
};

function formatSavedAgo(date: Date, t: (key: string, values?: Record<string, string>) => string): string {
  const seconds = Math.floor((Date.now() - date.getTime()) / 1000);
  if (seconds < 60) return t('autosave.savedJustNow');
  const minutes = Math.floor(seconds / 60);
  if (minutes < 60) return t('autosave.saved', { time: `${minutes}m` });
  const hours = Math.floor(minutes / 60);
  return t('autosave.saved', { time: `${hours}h` });
}

export function useNewsAutosave({
  dirty,
  readOnly,
  values,
  save,
  debounceMs = 2000,
}: UseNewsAutosaveOptions) {
  const t = useTranslations('news');
  const [status, setStatus] = useState<AutosaveStatus>('idle');
  const [lastSavedAt, setLastSavedAt] = useState<Date | null>(null);
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const savingRef = useRef(false);

  useEffect(() => {
    if (!dirty || readOnly) {
      if (timerRef.current) {
        clearTimeout(timerRef.current);
        timerRef.current = null;
      }
      return;
    }

    const validationError = validateNewsPostForm(values, { mode: 'save' });
    if (validationError) {
      setStatus('idle');
      return;
    }

    setStatus('pending');
    if (timerRef.current) clearTimeout(timerRef.current);

    timerRef.current = setTimeout(() => {
      void (async () => {
        if (savingRef.current) return;
        savingRef.current = true;
        setStatus('saving');
        try {
          const ok = await save({ silent: true });
          if (ok) {
            setLastSavedAt(new Date());
            setStatus('saved');
          } else {
            setStatus('error');
          }
        } catch {
          setStatus('error');
        } finally {
          savingRef.current = false;
        }
      })();
    }, debounceMs);

    return () => {
      if (timerRef.current) {
        clearTimeout(timerRef.current);
        timerRef.current = null;
      }
    };
  }, [debounceMs, dirty, readOnly, save, values]);

  const statusLabel = (() => {
    if (readOnly) return '';
    if (status === 'saving' || status === 'pending') return t('autosave.saving');
    if (status === 'error') return t('autosave.failed');
    if (status === 'saved' && lastSavedAt) return formatSavedAgo(lastSavedAt, t);
    if (dirty) return t('editor.unsaved');
    if (lastSavedAt) return formatSavedAgo(lastSavedAt, t);
    return '';
  })();

  return { status, lastSavedAt, statusLabel };
}
