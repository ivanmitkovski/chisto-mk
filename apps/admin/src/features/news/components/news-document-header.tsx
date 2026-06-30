'use client';

import { useCallback, useEffect, useRef } from 'react';
import { useTranslations } from 'next-intl';
import { localeCompleteness } from '../lib/news-locale-utils';
import type { NewsMediaDto } from '../news-api-types';
import type { NewsFormLocale, NewsPostFormValues } from '../types';
import { NEWS_LOCALES } from '../types';
import styles from './news-document-header.module.css';

type NewsDocumentHeaderProps = {
  values: NewsPostFormValues;
  locale: NewsFormLocale;
  media: NewsMediaDto[];
  hasCover: boolean;
  busy: boolean;
  readOnly: boolean;
  onLocaleChange: (locale: NewsFormLocale) => void;
  onChange: <K extends keyof NewsPostFormValues>(key: K, value: NewsPostFormValues[K]) => void;
};

function resizeField(element: HTMLTextAreaElement) {
  element.style.height = 'auto';
  element.style.height = `${element.scrollHeight}px`;
}

export function NewsDocumentHeader({
  values,
  locale,
  media,
  hasCover,
  busy,
  readOnly,
  onLocaleChange,
  onChange,
}: NewsDocumentHeaderProps) {
  const t = useTranslations('news');
  const titleRef = useRef<HTMLTextAreaElement>(null);
  const excerptRef = useRef<HTMLTextAreaElement>(null);
  const content = values.translations[locale];
  const scores = localeCompleteness(values, hasCover, media);

  useEffect(() => {
    if (titleRef.current) resizeField(titleRef.current);
    if (excerptRef.current) resizeField(excerptRef.current);
  }, [content.title, content.excerpt, locale]);

  const handleTitleChange = useCallback(
    (event: React.ChangeEvent<HTMLTextAreaElement>) => {
      resizeField(event.target);
      onChange('translations', {
        ...values.translations,
        [locale]: { ...content, title: event.target.value },
      });
    },
    [content, locale, onChange, values.translations],
  );

  const handleExcerptChange = useCallback(
    (event: React.ChangeEvent<HTMLTextAreaElement>) => {
      resizeField(event.target);
      onChange('translations', {
        ...values.translations,
        [locale]: { ...content, excerpt: event.target.value },
      });
    },
    [content, locale, onChange, values.translations],
  );

  return (
    <header className={styles.root}>
      <div className={styles.localeBar} role="tablist" aria-label={t('form.locales')}>
        {NEWS_LOCALES.map((loc) => {
          const selected = locale === loc;
          return (
            <button
              key={loc}
              type="button"
              role="tab"
              aria-selected={selected}
              className={selected ? styles.localeActive : styles.localeTab}
              disabled={busy}
              onClick={() => onLocaleChange(loc)}
            >
              {loc.toUpperCase()}
              <span
                className={scores[loc] ? styles.dotComplete : styles.dotIncomplete}
                aria-hidden
              />
            </button>
          );
        })}
      </div>

      <textarea
        ref={titleRef}
        className={styles.title}
        rows={1}
        value={content.title}
        onChange={handleTitleChange}
        disabled={busy || readOnly}
        placeholder={t('form.titlePlaceholder')}
        aria-label={t('form.title')}
        maxLength={200}
      />

      <textarea
        ref={excerptRef}
        className={styles.excerpt}
        rows={1}
        value={content.excerpt}
        onChange={handleExcerptChange}
        disabled={busy || readOnly}
        placeholder={t('form.excerptPlaceholder')}
        aria-label={t('form.excerpt')}
        maxLength={500}
      />

      <hr className={styles.divider} aria-hidden />
    </header>
  );
}
