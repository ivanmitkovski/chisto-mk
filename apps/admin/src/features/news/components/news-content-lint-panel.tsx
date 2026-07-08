'use client';

import { useMemo } from 'react';
import { useTranslations } from 'next-intl';
import { lintNewsContent, readingStatsFromBlocks, type NewsLintIssue } from '../lib/news-content-lint';
import type { NewsMediaDto } from '../news-api-types';
import type { NewsFormLocale, NewsPostFormValues } from '../types';
import { NEWS_LOCALES } from '../types';
import styles from './news-content-lint-panel.module.css';

export type NewsLintJumpTarget = 'title' | 'excerpt' | 'body' | 'cover' | 'media' | 'locale';

type NewsContentLintPanelProps = {
  values: NewsPostFormValues;
  locale: NewsFormLocale;
  hasCover: boolean;
  media: NewsMediaDto[];
  onJump?: ((target: NewsLintJumpTarget, issueLocale: NewsFormLocale) => void) | undefined;
};

function issueKey(issue: NewsLintIssue): string {
  return `${issue.locale}-${issue.id}-${issue.jump ?? 'none'}`;
}

export function NewsContentLintPanel({
  values,
  locale,
  hasCover,
  media,
  onJump,
}: NewsContentLintPanelProps) {
  const t = useTranslations('news');
  const issues = useMemo(() => lintNewsContent(values, hasCover, media), [values, hasCover, media]);
  const localeIssues = issues.filter((issue) => issue.locale === locale);
  const reading = readingStatsFromBlocks(values.translations[locale].body);

  const localeStats = useMemo(
    () =>
      NEWS_LOCALES.map((loc) => ({
        locale: loc,
        ...readingStatsFromBlocks(values.translations[loc].body),
      })),
    [values.translations],
  );

  return (
    <div className={styles.root}>
      <div className={styles.readingRow}>
        <span className={styles.readingStat}>
          {t('lint.wordCount', { count: reading.wordCount })}
        </span>
        <span className={styles.readingStat}>
          {t('lint.readingTime', { minutes: reading.readingMinutes })}
        </span>
      </div>

      <ul className={styles.localeStats} aria-label={t('lint.readingByLocale')}>
        {localeStats.map((row) => (
          <li key={row.locale}>
            <span className={styles.localeCode}>{row.locale.toUpperCase()}</span>
            <span>{t('lint.wordCount', { count: row.wordCount })}</span>
            <span>{t('lint.readingTime', { minutes: row.readingMinutes })}</span>
          </li>
        ))}
      </ul>

      {localeIssues.length === 0 ? (
        <p className={styles.clear}>{t('lint.noIssues')}</p>
      ) : (
        <ul className={styles.issueList}>
          {localeIssues.map((issue) => (
            <li key={issueKey(issue)} className={issue.severity === 'error' ? styles.issueError : styles.issueWarning}>
              <span>{t(issue.messageKey)}</span>
              {issue.jump && onJump ? (
                <button
                  type="button"
                  className={styles.jumpBtn}
                  onClick={() => onJump(issue.jump!, issue.locale)}
                >
                  {t('lint.jump')}
                </button>
              ) : null}
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}
