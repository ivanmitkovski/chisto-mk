'use client';

import { useEffect, useRef, useState } from 'react';
import { useTranslations } from 'next-intl';
import { newsFormSaveFingerprint } from '../lib/news-save-payload';
import { validateNewsPostForAutosave } from '../lib/news-post-policy';
import type { NewsPostFormValues } from '../types';
import type { NewsMediaDto, NewsPostStatusApi } from '../news-api-types';

type AutosaveStatus = 'idle' | 'pending' | 'saving' | 'saved' | 'error';

type UseNewsAutosaveOptions = {
  dirty: boolean;
  readOnly: boolean;
  /** When false, autosave is fully disabled (e.g. published posts). */
  enabled?: boolean;
  values: NewsPostFormValues;
  save: (options?: { silent?: boolean }) => Promise<boolean>;
  post: { status: NewsPostStatusApi; coverMediaId: string | null; media: NewsMediaDto[] };
  debounceMs?: number;
  online?: boolean;
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
  enabled = true,
  values,
  save,
  post,
  debounceMs = 2000,
  online = true,
}: UseNewsAutosaveOptions) {
  const t = useTranslations('news');
  const [status, setStatus] = useState<AutosaveStatus>('idle');
  const [lastSavedAt, setLastSavedAt] = useState<Date | null>(null);
  const [autosavePaused, setAutosavePaused] = useState(false);
  const timerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const savingRef = useRef(false);
  const valuesRef = useRef(values);
  valuesRef.current = values;

  const saveRef = useRef(save);
  saveRef.current = save;

  const fingerprint = newsFormSaveFingerprint(values);
  const pausedFingerprintRef = useRef<string | null>(null);

  useEffect(() => {
    if (!dirty) {
      pausedFingerprintRef.current = null;
      setAutosavePaused(false);
    }
  }, [dirty]);

  useEffect(() => {
    if (!online) {
      if (timerRef.current) {
        clearTimeout(timerRef.current);
        timerRef.current = null;
      }
      setStatus((current) => (current === 'pending' || current === 'saving' ? 'idle' : current));
    }
  }, [online]);

  useEffect(() => {
    if (!enabled || !dirty || readOnly || autosavePaused || !online) {
      if (timerRef.current) {
        clearTimeout(timerRef.current);
        timerRef.current = null;
      }
      return;
    }

    const validationError = validateNewsPostForAutosave(valuesRef.current, post);
    if (validationError) {
      setStatus('idle');
      return;
    }

    if (pausedFingerprintRef.current === fingerprint) {
      setStatus('error');
      return;
    }

    setStatus('pending');
    if (timerRef.current) clearTimeout(timerRef.current);

    timerRef.current = setTimeout(() => {
      void (async () => {
        if (savingRef.current) return;

        const attemptFingerprint = newsFormSaveFingerprint(valuesRef.current);
        if (pausedFingerprintRef.current === attemptFingerprint) {
          setStatus('error');
          return;
        }

        savingRef.current = true;
        setStatus('saving');
        try {
          const ok = await saveRef.current({ silent: true });
          if (ok) {
            pausedFingerprintRef.current = null;
            setAutosavePaused(false);
            setLastSavedAt(new Date());
            setStatus('saved');
          } else {
            pausedFingerprintRef.current = attemptFingerprint;
            setAutosavePaused(true);
            setStatus('error');
          }
        } catch {
          pausedFingerprintRef.current = attemptFingerprint;
          setAutosavePaused(true);
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
  }, [autosavePaused, debounceMs, dirty, enabled, fingerprint, online, post, readOnly]);

  const statusLabel = (() => {
    if (readOnly || !enabled) return '';
    if (status === 'saving' || status === 'pending') return t('autosave.saving');
    if (status === 'error') return t('autosave.failed');
    if (status === 'saved' && lastSavedAt) return formatSavedAgo(lastSavedAt, t);
    if (dirty) return t('editor.unsaved');
    if (lastSavedAt) return formatSavedAgo(lastSavedAt, t);
    return '';
  })();

  const retrySave = () => {
    pausedFingerprintRef.current = null;
    setAutosavePaused(false);
    setStatus('saving');
    void (async () => {
      const ok = await save({ silent: true });
      if (ok) {
        pausedFingerprintRef.current = null;
        setAutosavePaused(false);
        setLastSavedAt(new Date());
        setStatus('saved');
      } else {
        const attemptFingerprint = newsFormSaveFingerprint(valuesRef.current);
        pausedFingerprintRef.current = attemptFingerprint;
        setAutosavePaused(true);
        setStatus('error');
      }
    })();
  };

  return { status, lastSavedAt, statusLabel, retrySave, canRetry: status === 'error' };
}
