'use client';

import Link from 'next/link';
import { useTranslations } from 'next-intl';
import type { NewsPostAdminDto } from '../news-api-types';
import styles from './news-editor-meta-panel.module.css';

type NewsEditorMetaPanelProps = {
  post: NewsPostAdminDto;
  locale: string;
};

function scheduleTimezoneLabel(iso: string | null): string | null {
  if (!iso) return null;
  try {
    return Intl.DateTimeFormat().resolvedOptions().timeZone;
  } catch {
    return null;
  }
}

export function NewsEditorMetaPanel({ post, locale }: NewsEditorMetaPanelProps) {
  const t = useTranslations('news');
  const landingUrl =
    post.status === 'published' || post.status === 'scheduled'
      ? `https://chisto.mk/${locale}/news/${post.slug}`
      : null;
  const tz = scheduleTimezoneLabel(post.scheduledAt);

  return (
    <aside className={styles.root} aria-label={t('meta.label')}>
      <dl className={styles.list}>
        <div>
          <dt>{t('meta.created')}</dt>
          <dd>{new Date(post.createdAt).toLocaleString()}</dd>
        </div>
        <div>
          <dt>{t('meta.updated')}</dt>
          <dd>{new Date(post.updatedAt).toLocaleString()}</dd>
        </div>
        {post.publishedAt ? (
          <div>
            <dt>{t('meta.published')}</dt>
            <dd>{new Date(post.publishedAt).toLocaleString()}</dd>
          </div>
        ) : null}
        {post.scheduledAt ? (
          <div>
            <dt>{t('meta.scheduled')}</dt>
            <dd>
              {new Date(post.scheduledAt).toLocaleString()}
              {tz ? (
                <span className={styles.tzHint}>{t('meta.scheduleTimezone', { timezone: tz })}</span>
              ) : null}
            </dd>
          </div>
        ) : null}
      </dl>
      {landingUrl ? (
        <Link href={landingUrl} target="_blank" rel="noopener noreferrer" className={styles.previewLink}>
          {t('meta.viewOnSite')}
        </Link>
      ) : (
        <p className={styles.previewHint}>{t('meta.previewHint')}</p>
      )}
      <p className={styles.shortcuts}>{t('meta.shortcuts')}</p>
    </aside>
  );
}
