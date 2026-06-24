'use client';

import { useTranslations } from 'next-intl';
import { localeCompleteness } from '../lib/news-locale-utils';
import type { NewsPostFormValues } from '../types';
import { NEWS_LOCALES } from '../types';
import styles from './news-locale-completeness.module.css';

type NewsLocaleCompletenessProps = {
  values: NewsPostFormValues;
  hasCover: boolean;
  activeLocale: string;
};

export function NewsLocaleCompleteness({
  values,
  hasCover,
  activeLocale,
}: NewsLocaleCompletenessProps) {
  const t = useTranslations('news');
  const scores = localeCompleteness(values, hasCover);

  return (
    <div className={styles.root} role="status">
      <span className={styles.label}>{t('completeness.label')}</span>
      <ul className={styles.list}>
        {NEWS_LOCALES.map((loc) => (
          <li key={loc}>
            <span
              className={scores[loc] ? styles.complete : styles.incomplete}
              aria-current={loc === activeLocale ? 'true' : undefined}
            >
              {loc.toUpperCase()}
            </span>
          </li>
        ))}
      </ul>
      {!hasCover ? <p className={styles.hint}>{t('completeness.coverMissing')}</p> : null}
    </div>
  );
}
