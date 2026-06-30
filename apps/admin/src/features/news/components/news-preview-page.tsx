'use client';

import { useRouter, useSearchParams } from 'next/navigation';
import { useTranslations } from 'next-intl';
import { useCallback, useEffect, useMemo, useState } from 'react';
import { Button, PageHeader, Select } from '@/components/ui';
import { landingNewsArticleUrl } from '../lib/landing-site-url';
import {
  NEWS_PREVIEW_CHANNEL,
  readNewsPreviewSession,
  type NewsPreviewSessionPayload,
} from '../lib/news-preview-session';
import type { NewsPostAdminDto } from '../news-api-types';
import { postToFormValues } from '../types';
import type { NewsFormLocale } from '../types';
import { NEWS_LOCALES } from '../types';
import { NewsLivePreview } from './news-live-preview';
import styles from './news-preview-page.module.css';

type NewsPreviewPageProps = {
  post: NewsPostAdminDto;
};

function coverAltForLocale(
  media: NewsPostAdminDto['media'],
  coverMediaId: string | null,
  locale: NewsFormLocale,
): string | null {
  if (!coverMediaId) return null;
  const cover = media.find((m) => m.id === coverMediaId);
  if (!cover?.altText) return null;
  return cover.altText[locale]?.trim() || cover.altText.en?.trim() || null;
}

function sessionFromPost(post: NewsPostAdminDto, locale: NewsFormLocale): NewsPreviewSessionPayload {
  return {
    postId: post.id,
    locale,
    values: postToFormValues(post),
    media: post.media,
    coverImageUrl: post.coverImageUrl,
    coverMediaId: post.coverMediaId,
    status: post.status,
    category: post.category,
    updatedAt: Date.now(),
  };
}

export function NewsPreviewPage({ post }: NewsPreviewPageProps) {
  const t = useTranslations('news');
  const router = useRouter();
  const searchParams = useSearchParams();
  const initialLocale = (searchParams.get('locale') as NewsFormLocale | null) ?? 'en';
  const [displayLocale, setDisplayLocale] = useState<NewsFormLocale>(
    NEWS_LOCALES.includes(initialLocale) ? initialLocale : 'en',
  );
  const [session, setSession] = useState<NewsPreviewSessionPayload | null>(null);
  const [live, setLive] = useState(true);

  const refreshSession = useCallback(() => {
    const stored = readNewsPreviewSession(post.id);
    if (stored) {
      setSession(stored);
      if (live) {
        setDisplayLocale(stored.locale);
      }
      return;
    }
    setSession(sessionFromPost(post, displayLocale));
  }, [displayLocale, live, post]);

  useEffect(() => {
    refreshSession();
  }, [refreshSession]);

  useEffect(() => {
    function onStorage(e: StorageEvent) {
      if (!e.key?.includes(post.id)) return;
      refreshSession();
    }
    window.addEventListener('storage', onStorage);
    return () => window.removeEventListener('storage', onStorage);
  }, [post.id, refreshSession]);

  useEffect(() => {
    if (!live) return;
    let channel: BroadcastChannel | null = null;
    if (typeof BroadcastChannel !== 'undefined') {
      channel = new BroadcastChannel(NEWS_PREVIEW_CHANNEL);
      channel.onmessage = (event) => {
        const data = event.data as { postId?: string };
        if (data.postId === post.id) refreshSession();
      };
    }
    const intervalId = window.setInterval(refreshSession, 2000);
    return () => {
      channel?.close();
      window.clearInterval(intervalId);
    };
  }, [live, post.id, refreshSession]);

  const previewData = session ?? sessionFromPost(post, displayLocale);
  const categoryLabel = t(`category.${previewData.values.category}`);
  const coverAltText = useMemo(
    () => coverAltForLocale(previewData.media, previewData.coverMediaId, displayLocale),
    [displayLocale, previewData.coverMediaId, previewData.media],
  );
  const liveSiteUrl =
    previewData.status === 'published' && previewData.values.slug.trim()
      ? landingNewsArticleUrl(displayLocale, previewData.values.slug.trim())
      : null;

  return (
    <div className={styles.root}>
      <PageHeader
        title={previewData.values.translations[displayLocale].title || post.slug}
        description={t('preview.fullPageDescription')}
        actions={
          <div className={styles.actions}>
            <Button variant="outline" onClick={() => router.push(`/dashboard/news/${post.id}`)}>
              {t('preview.backToEditor')}
            </Button>
            <Button variant="outline" onClick={refreshSession}>
              {t('preview.refresh')}
            </Button>
            <Button variant={live ? 'solid' : 'outline'} size="sm" onClick={() => setLive((v) => !v)}>
              {live ? t('preview.liveOn') : t('preview.liveOff')}
            </Button>
            {liveSiteUrl ? (
              <Button variant="outline" onClick={() => window.open(liveSiteUrl, '_blank', 'noopener,noreferrer')}>
                {t('preview.viewLiveSite')}
              </Button>
            ) : null}
          </div>
        }
      />

      <div className={styles.toolbar}>
        <Select
          label={t('form.locales')}
          value={displayLocale}
          options={NEWS_LOCALES.map((loc) => ({ value: loc, label: loc.toUpperCase() }))}
          onChange={(e) => setDisplayLocale(e.target.value as NewsFormLocale)}
        />
        {session && session.updatedAt ? (
          <p className={styles.syncHint} role="status">
            {live ? t('preview.syncLive') : t('preview.syncPaused')}
          </p>
        ) : (
          <p className={styles.syncHint} role="status">
            {t('preview.savedSnapshot')}
          </p>
        )}
      </div>

      <div className={styles.canvas}>
        <NewsLivePreview
          values={previewData.values}
          locale={displayLocale}
          media={previewData.media}
          coverImageUrl={previewData.coverImageUrl}
          coverAltText={coverAltText}
          status={previewData.status}
          categoryLabel={categoryLabel}
          fullPage
        />
      </div>
    </div>
  );
}
