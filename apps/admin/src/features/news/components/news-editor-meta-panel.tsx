'use client';

import Link from 'next/link';
import { useTranslations } from 'next-intl';
import { useMemo } from 'react';
import { toDatetimeLocalValue } from '@/lib/datetime/datetime-local';
import { landingNewsArticleUrl } from '../lib/landing-site-url';
import type { NewsPostAdminDto } from '../news-api-types';
import type { NewsFormLocale, NewsPostFormValues } from '../types';
import styles from './news-editor-meta-panel.module.css';

type NewsEditorMetaPanelProps = {
  post: NewsPostAdminDto;
  values: NewsPostFormValues;
  locale: NewsFormLocale;
  status: string;
};

function scheduleTimezoneLabel(): string | null {
  try {
    return Intl.DateTimeFormat().resolvedOptions().timeZone;
  } catch {
    return null;
  }
}

function isMacPlatform(): boolean {
  if (typeof navigator === 'undefined') return true;
  return navigator.platform.toLowerCase().includes('mac');
}

function formatLocalDateTime(value: string): string {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return value;
  return date.toLocaleString();
}

export function NewsEditorMetaPanel({ post, values, locale, status }: NewsEditorMetaPanelProps) {
  const t = useTranslations('news');
  const slug = values.slug.trim() || post.slug;
  const landingUrl = landingNewsArticleUrl(locale, slug);
  const canViewOnSite = status === 'published' || status === 'scheduled';
  const tz = scheduleTimezoneLabel();
  const shortcuts = useMemo(
    () => (isMacPlatform() ? t('meta.shortcuts') : t('meta.shortcutsWin')),
    [t],
  );

  const savedSchedule = post.scheduledAt;
  const draftSchedule = values.scheduledAt.trim();
  const savedScheduleLocal = toDatetimeLocalValue(savedSchedule);
  const schedulePendingSave = Boolean(draftSchedule && draftSchedule !== savedScheduleLocal);

  return (
    <div className={styles.root}>
      <dl className={styles.list}>
        <div>
          <dt>{t('meta.created')}</dt>
          <dd>{formatLocalDateTime(post.createdAt)}</dd>
        </div>
        <div>
          <dt>{t('meta.updated')}</dt>
          <dd>{formatLocalDateTime(post.updatedAt)}</dd>
        </div>
        {post.publishedAt ? (
          <div>
            <dt>{t('meta.published')}</dt>
            <dd>{formatLocalDateTime(post.publishedAt)}</dd>
          </div>
        ) : null}
        {savedSchedule ? (
          <div>
            <dt>{t('meta.scheduled')}</dt>
            <dd>
              {formatLocalDateTime(savedSchedule)}
              {tz ? (
                <span className={styles.tzHint}>{t('meta.scheduleTimezone', { timezone: tz })}</span>
              ) : null}
            </dd>
          </div>
        ) : null}
        {schedulePendingSave && draftSchedule ? (
          <div>
            <dt>{t('meta.scheduledDraft')}</dt>
            <dd>
              {(() => {
                const parsed = new Date(draftSchedule);
                return Number.isNaN(parsed.getTime()) ? draftSchedule : parsed.toLocaleString();
              })()}
              <span className={styles.pendingHint}>{t('meta.unsavedSchedule')}</span>
            </dd>
          </div>
        ) : null}
      </dl>
      {canViewOnSite ? (
        <Link href={landingUrl} target="_blank" rel="noopener noreferrer" className={styles.previewLink}>
          {t('meta.viewOnSite')}
        </Link>
      ) : (
        <p className={styles.previewHint}>{t('meta.previewHint')}</p>
      )}
      <p className={styles.canonicalHint}>
        {t('meta.publicUrl')}: <span className={styles.canonicalUrl}>{landingUrl}</span>
      </p>
      <p className={styles.shortcuts}>{shortcuts}</p>
    </div>
  );
}
