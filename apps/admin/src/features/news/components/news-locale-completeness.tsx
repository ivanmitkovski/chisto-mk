'use client';

import { useTranslations } from 'next-intl';
import { localeCompleteness, countIncompleteLocales } from '../lib/news-locale-utils';
import type { NewsMediaDto } from '../news-api-types';
import type { NewsPostFormValues } from '../types';
import { NEWS_LOCALES } from '../types';
import styles from './news-locale-completeness.module.css';

type NewsLocaleCompletenessProps = {
  values: NewsPostFormValues;
  hasCover: boolean;
  media: NewsMediaDto[];
  activeLocale: string;
};

export function NewsLocaleCompleteness({
  values,
  hasCover,
  media,
  activeLocale,
}: NewsLocaleCompletenessProps) {
  const t = useTranslations('news');
  const scores = localeCompleteness(values, hasCover, media);
  const incompleteCount = countIncompleteLocales(values, hasCover, media);

  return (
    <div className={styles.root} role="status">
      <span className={styles.label}>{t('completeness.label')}</span>
      {incompleteCount > 0 ? (
        <span className={styles.incompleteCount}>
          {t('completeness.incompleteCount', { count: incompleteCount })}
        </span>
      ) : (
        <span className={styles.allReady}>{t('completeness.allReady')}</span>
      )}
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
