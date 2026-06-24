'use client';

import Image from 'next/image';
import { useState } from 'react';
import { useTranslations } from 'next-intl';
import type { NewsPostFormValues } from '../types';
import type { NewsFormLocale } from '../types';
import type { NewsMediaDto } from '../news-api-types';
import { NewsPreviewBlocks, resolvePreviewBlocks } from './news-preview-blocks';
import styles from './news-live-preview.module.css';

type DevicePreset = 'desktop' | 'tablet' | 'phone';

type NewsLivePreviewProps = {
  values: NewsPostFormValues;
  locale: NewsFormLocale;
  media: NewsMediaDto[];
  coverImageUrl: string | null;
  status: string;
  categoryLabel: string;
};

export function NewsLivePreview({
  values,
  locale,
  media,
  coverImageUrl,
  status,
  categoryLabel,
}: NewsLivePreviewProps) {
  const t = useTranslations('news');
  const [device, setDevice] = useState<DevicePreset>('desktop');
  const content = values.translations[locale];
  const body = resolvePreviewBlocks(content.body, media, locale);
  const isDraft = status !== 'published';

  return (
    <section className={styles.root} aria-label={t('preview.label')}>
      <div className={styles.header}>
        <h3 className={styles.heading}>{t('preview.label')}</h3>
        <div className={styles.deviceTabs} role="tablist" aria-label={t('preview.devices')}>
          {(['desktop', 'tablet', 'phone'] as const).map((preset) => (
            <button
              key={preset}
              type="button"
              role="tab"
              aria-selected={device === preset}
              className={device === preset ? styles.deviceActive : styles.deviceTab}
              onClick={() => setDevice(preset)}
            >
              {t(`preview.device_${preset}`)}
            </button>
          ))}
        </div>
      </div>
      <div className={`${styles.chrome} ${styles[`device_${device}`]}`}>
        {isDraft ? (
          <div className={styles.watermark} role="status">
            {t('preview.draftWatermark')}
          </div>
        ) : null}
        <div className={styles.article}>
          <div className={styles.meta}>
            <span className={styles.category}>{categoryLabel}</span>
          </div>
          <h1 className={styles.title}>{content.title || t('form.title')}</h1>
          {content.excerpt ? <p className={styles.excerpt}>{content.excerpt}</p> : null}
          {coverImageUrl ? (
            <div className={styles.cover}>
              <Image
                src={coverImageUrl}
                alt=""
                fill
                className={styles.coverImage}
                sizes="(min-width: 896px) 896px, 100vw"
                unoptimized
              />
            </div>
          ) : null}
          <div className={styles.body}>
            <NewsPreviewBlocks body={body} />
          </div>
        </div>
      </div>
    </section>
  );
}
