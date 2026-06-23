'use client';

import { useCallback, useState } from 'react';
import type { NewsPostFormValues } from '../types';
import { emptyTranslations } from '../types';

export function useNewsPostForm(initial?: Partial<NewsPostFormValues>) {
  const [values, setValues] = useState<NewsPostFormValues>({
    slug: initial?.slug ?? '',
    category: initial?.category ?? 'release',
    scheduledAt: initial?.scheduledAt ?? '',
    translations: initial?.translations ?? emptyTranslations(),
  });
  const [dirty, setDirty] = useState(false);

  const onChange = useCallback(<K extends keyof NewsPostFormValues>(key: K, value: NewsPostFormValues[K]) => {
    setValues((prev) => ({ ...prev, [key]: value }));
    setDirty(true);
  }, []);

  const reset = useCallback((next: NewsPostFormValues) => {
    setValues(next);
    setDirty(false);
  }, []);

  return { values, dirty, onChange, reset, setDirty };
}
