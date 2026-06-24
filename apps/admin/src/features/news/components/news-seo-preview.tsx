'use client';

import { useEffect, useState } from 'react';
import { useTranslations } from 'next-intl';
import { listNewsPostsClient } from '../data/news-adapter-client';
import type { NewsPostFormValues } from '../types';
import type { NewsFormLocale } from '../types';
import styles from './news-seo-preview.module.css';

const TITLE_LIMIT = 60;
const DESCRIPTION_LIMIT = 160;

type NewsSeoPreviewProps = {
  postId: string;
  values: NewsPostFormValues;
  locale: NewsFormLocale;
  coverImageUrl: string | null;
  publishedAt: string | null;
};

export function NewsSeoPreview({
  postId,
  values,
  locale,
  coverImageUrl,
  publishedAt,
}: NewsSeoPreviewProps) {
  const t = useTranslations('news');
  const content = values.translations[locale];
  const slug = values.slug.trim() || 'your-slug';
  const canonical = `https://chisto.mk/${locale}/news/${slug}`;
  const titleLen = content.title.length;
  const descLen = content.excerpt.length;
  const jsonLdReady = Boolean(
    content.title.trim() && content.excerpt.trim() && coverImageUrl && publishedAt,
  );

  const [slugStatus, setSlugStatus] = useState<'idle' | 'checking' | 'available' | 'taken'>('idle');

  useEffect(() => {
    const trimmed = values.slug.trim();
    if (!trimmed) {
      setSlugStatus('idle');
      return;
    }

    setSlugStatus('checking');
    const timer = setTimeout(() => {
      void (async () => {
        try {
          const result = await listNewsPostsClient({ q: trimmed, page: 1 });
          const conflict = result.items.some(
            (item) => item.slug === trimmed && item.id !== postId,
          );
          setSlugStatus(conflict ? 'taken' : 'available');
        } catch {
          setSlugStatus('idle');
        }
      })();
    }, 400);

    return () => clearTimeout(timer);
  }, [postId, values.slug]);

  return (
    <section className={styles.root} aria-label={t('seo.label')}>
      <h3 className={styles.heading}>{t('seo.label')}</h3>

      <div className={styles.block}>
        <h4 className={styles.subheading}>{t('seo.googleTitle')}</h4>
        <div className={styles.googleSnippet}>
          <p className={styles.googleUrl}>{canonical}</p>
          <p className={styles.googleHeadline}>{content.title || '—'}</p>
          <p className={styles.googleDesc}>{content.excerpt || '—'}</p>
        </div>
        {titleLen > TITLE_LIMIT ? (
          <p className={styles.warn}>{t('seo.titleTooLong', { count: titleLen })}</p>
        ) : null}
        {descLen > DESCRIPTION_LIMIT ? (
          <p className={styles.warn}>{t('seo.descriptionTooLong', { count: descLen })}</p>
        ) : null}
        <p className={styles.canonical}>
          {t('seo.canonical')}: {canonical}
        </p>
        {slugStatus === 'available' ? (
          <p className={styles.jsonLdOk}>{t('seo.slugAvailable')}</p>
        ) : null}
        {slugStatus === 'taken' ? (
          <p className={styles.warn}>{t('seo.slugTaken')}</p>
        ) : null}
      </div>

      <div className={styles.block}>
        <h4 className={styles.subheading}>{t('seo.openGraph')}</h4>
        <div className={styles.socialCard}>
          {coverImageUrl ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={coverImageUrl} alt="" className={styles.ogImage} />
          ) : (
            <div className={styles.ogPlaceholder} />
          )}
          <div className={styles.ogBody}>
            <p className={styles.ogSite}>chisto.mk</p>
            <p className={styles.ogTitle}>{content.title || '—'}</p>
            <p className={styles.ogDesc}>{content.excerpt || '—'}</p>
          </div>
        </div>
      </div>

      <div className={styles.block}>
        <h4 className={styles.subheading}>{t('seo.twitter')}</h4>
        <div className={styles.socialCard}>
          {coverImageUrl ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img src={coverImageUrl} alt="" className={styles.ogImage} />
          ) : (
            <div className={styles.ogPlaceholder} />
          )}
          <div className={styles.ogBody}>
            <p className={styles.ogTitle}>{content.title || '—'}</p>
            <p className={styles.ogDesc}>{content.excerpt || '—'}</p>
          </div>
        </div>
      </div>

      <p className={jsonLdReady ? styles.jsonLdOk : styles.jsonLdWarn}>
        {jsonLdReady ? t('seo.jsonLdReady') : t('seo.jsonLdIncomplete')}
      </p>
    </section>
  );
}
