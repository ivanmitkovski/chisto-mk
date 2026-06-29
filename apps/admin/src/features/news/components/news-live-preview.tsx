'use client';

import Image from 'next/image';
import { useCallback, useState } from 'react';
import { useTranslations } from 'next-intl';
import type { NewsPostFormValues } from '../types';
import type { NewsFormLocale } from '../types';
import type { NewsMediaDto } from '../news-api-types';
import { NewsPreviewBlocks, resolvePreviewBlocks } from './news-preview-blocks';
import styles from './news-live-preview.module.css';

export type DevicePreset = 'desktop' | 'tablet' | 'phone';

const DEVICE_PRESETS: DevicePreset[] = ['desktop', 'tablet', 'phone'];

type NewsLivePreviewProps = {
  values: NewsPostFormValues;
  locale: NewsFormLocale;
  media: NewsMediaDto[];
  coverImageUrl: string | null;
  coverAltText?: string | null;
  status: string;
  categoryLabel: string;
  fullPage?: boolean;
  initialDevice?: DevicePreset;
};

function PreviewArticle({
  values,
  locale,
  media,
  coverImageUrl,
  coverAltText,
  status,
  categoryLabel,
  device,
  fullPage,
}: NewsLivePreviewProps & { device: DevicePreset }) {
  const t = useTranslations('news');
  const content = values.translations[locale];
  const body = resolvePreviewBlocks(content.body, media, locale);
  const isDraft = status !== 'published';
  const coverAlt = coverAltText?.trim() || content.title || t('form.cover');

  return (
    <div
      className={[
        styles.chrome,
        styles[`device_${device}`],
        fullPage ? styles.chromeFullPage : '',
      ]
        .filter(Boolean)
        .join(' ')}
      data-device={device}
    >
      {isDraft ? (
        <div className={styles.watermark} role="status">
          {t('preview.draftWatermark')}
        </div>
      ) : null}
      <div className={fullPage ? styles.articleFullPage : styles.article}>
        <div className={styles.meta}>
          <span className={styles.category}>{categoryLabel}</span>
        </div>
        <h1 className={fullPage ? styles.titleFullPage : styles.title}>
          {content.title || t('form.title')}
        </h1>
        {content.excerpt ? (
          <p className={fullPage ? styles.excerptFullPage : styles.excerpt}>{content.excerpt}</p>
        ) : null}
        {coverImageUrl ? (
          <div className={fullPage ? styles.coverFullPage : styles.cover}>
            <Image
              src={coverImageUrl}
              alt={coverAlt}
              fill
              className={styles.coverImage}
              sizes={
                device === 'phone'
                  ? '390px'
                  : device === 'tablet'
                    ? '768px'
                    : '(min-width: 896px) 896px, 100vw'
              }
              unoptimized
              {...(fullPage ? { priority: true } : {})}
            />
          </div>
        ) : null}
        <div className={fullPage ? styles.bodyFullPage : styles.body}>
          <NewsPreviewBlocks body={body} />
        </div>
      </div>
    </div>
  );
}

export function NewsLivePreview({
  fullPage = false,
  initialDevice = 'desktop',
  ...props
}: NewsLivePreviewProps) {
  const t = useTranslations('news');
  const [device, setDevice] = useState<DevicePreset>(initialDevice);

  const selectDevice = useCallback((next: DevicePreset) => {
    setDevice(next);
  }, []);

  const handleDeviceKeyDown = useCallback(
    (event: React.KeyboardEvent<HTMLDivElement>) => {
      const index = DEVICE_PRESETS.indexOf(device);
      if (index < 0) return;
      if (event.key === 'ArrowRight' || event.key === 'ArrowDown') {
        event.preventDefault();
        setDevice(DEVICE_PRESETS[(index + 1) % DEVICE_PRESETS.length]!);
      } else if (event.key === 'ArrowLeft' || event.key === 'ArrowUp') {
        event.preventDefault();
        setDevice(DEVICE_PRESETS[(index - 1 + DEVICE_PRESETS.length) % DEVICE_PRESETS.length]!);
      } else if (event.key === 'Home') {
        event.preventDefault();
        setDevice('desktop');
      } else if (event.key === 'End') {
        event.preventDefault();
        setDevice('phone');
      }
    },
    [device],
  );

  return (
    <section
      className={fullPage ? styles.rootFullPage : styles.root}
      aria-label={t('preview.label')}
    >
      {!fullPage ? (
        <div className={styles.header}>
          <h3 className={styles.heading}>{t('preview.label')}</h3>
        </div>
      ) : null}

      <div
        className={styles.deviceToolbar}
        role="tablist"
        aria-label={t('preview.devices')}
        onKeyDown={handleDeviceKeyDown}
      >
        {DEVICE_PRESETS.map((preset) => {
          const selected = device === preset;
          return (
            <button
              key={preset}
              type="button"
              role="tab"
              id={`news-preview-device-${preset}`}
              aria-selected={selected}
              aria-controls="news-preview-device-panel"
              tabIndex={selected ? 0 : -1}
              className={selected ? `${styles.deviceTab} ${styles.deviceActive}` : styles.deviceTab}
              onClick={() => selectDevice(preset)}
            >
              {t(`preview.device_${preset}`)}
            </button>
          );
        })}
      </div>

      <div
        id="news-preview-device-panel"
        role="tabpanel"
        aria-labelledby={`news-preview-device-${device}`}
        className={styles.deviceStage}
      >
        <PreviewArticle {...props} device={device} fullPage={fullPage} />
      </div>
    </section>
  );
}
