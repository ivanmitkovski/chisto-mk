'use client';

import { useLocale } from 'next-intl';
import { useMemo } from 'react';
import { createTranslator } from 'use-intl';
import { getStaticNewsMessages } from '@/i18n/static-news-messages';

/** News strings from bundled JSON — bypasses stale route-message merges in IntlProvider. */
export function useStaticNewsTranslations(): (
  key: string,
  values?: Record<string, string | number | Date>,
) => string {
  const locale = useLocale();

  return useMemo(() => {
    const translate = createTranslator({
      locale,
      messages: { news: getStaticNewsMessages(locale) },
      namespace: 'news',
    });
    return (key, values) => translate(key as never, values as never);
  }, [locale]);
}
