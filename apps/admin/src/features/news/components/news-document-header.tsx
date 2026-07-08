'use client';

import { useCallback, useEffect, useRef } from 'react';
import { useTranslations } from 'next-intl';
import { Icon } from '@/components/ui';
import { localeCompleteness } from '../lib/news-locale-utils';
import { MAX_EXCERPT_LENGTH, MAX_TITLE_LENGTH } from '../lib/news-post-policy';
import type { NewsMediaDto } from '../news-api-types';
import type { NewsFormLocale, NewsPostFormValues } from '../types';
import { NEWS_LOCALES } from '../types';
import styles from './news-document-header.module.css';

/** Counters stay hidden until the field is at 80% of its hard limit. */
function counterVisible(length: number, max: number): boolean {
  return length >= max * 0.8;
}

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
              aria-label={`${loc.toUpperCase()} — ${
                scores[loc] ? t('localeStatus.complete') : t('localeStatus.incomplete')
              }`}
              className={selected ? styles.localeActive : styles.localeTab}
              disabled={busy}
              onClick={() => onLocaleChange(loc)}
            >
              {loc.toUpperCase()}
              <span
                className={scores[loc] ? styles.ringComplete : styles.ringIncomplete}
                aria-hidden
              >
                {scores[loc] ? <Icon name="check" size={9} strokeWidth={3} /> : null}
              </span>
            </button>
          );
        })}
      </div>

      <textarea
        ref={titleRef}
        id="news-document-title"
        className={styles.title}
        rows={1}
        value={content.title}
        onChange={handleTitleChange}
        disabled={busy || readOnly}
        placeholder={t('form.titlePlaceholder')}
        aria-label={t('form.title')}
        maxLength={MAX_TITLE_LENGTH}
      />
      {counterVisible(content.title.length, MAX_TITLE_LENGTH) ? (
        <p className={styles.counter} aria-live="polite">
          {content.title.length} / {MAX_TITLE_LENGTH}
        </p>
      ) : null}

      <textarea
        ref={excerptRef}
        id="news-document-excerpt"
        className={styles.excerpt}
        rows={1}
        value={content.excerpt}
        onChange={handleExcerptChange}
        disabled={busy || readOnly}
        placeholder={t('form.excerptPlaceholder')}
        aria-label={t('form.excerpt')}
        maxLength={MAX_EXCERPT_LENGTH}
      />
      {counterVisible(content.excerpt.length, MAX_EXCERPT_LENGTH) ? (
        <p className={styles.counter} aria-live="polite">
          {content.excerpt.length} / {MAX_EXCERPT_LENGTH}
        </p>
      ) : null}

      <hr className={styles.divider} aria-hidden />
    </header>
  );
}
