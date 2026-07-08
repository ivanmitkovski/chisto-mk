'use client';

import { useCallback, useState } from 'react';
import type { NewsPostFormValues } from '../types';
import { emptyTranslations } from '../types';

export function useNewsPostForm(initial?: Partial<NewsPostFormValues>) {
  const [values, setValues] = useState<NewsPostFormValues>({
    slug: initial?.slug ?? '',
    category: initial?.category ?? 'release',
    scheduledAt: initial?.scheduledAt ?? '',
    featured: initial?.featured ?? false,
    translations: initial?.translations ?? emptyTranslations(),
  });

  const onChange = useCallback(<K extends keyof NewsPostFormValues>(key: K, value: NewsPostFormValues[K]) => {
    setValues((prev) => ({ ...prev, [key]: value }));
  }, []);

  const reset = useCallback((next: NewsPostFormValues) => {
    setValues(next);
  }, []);

  return { values, onChange, reset };
}
