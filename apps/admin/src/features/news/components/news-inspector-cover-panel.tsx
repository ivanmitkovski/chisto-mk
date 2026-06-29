'use client';

import Image from 'next/image';
import { useTranslations } from 'next-intl';
import { Input } from '@/components/ui';
import { coverAltTextForLocale } from '../lib/news-locale-utils';
import type { NewsMediaDto } from '../news-api-types';
import type { NewsFormLocale } from '../types';
import styles from './news-inspector-cover-panel.module.css';

type NewsInspectorCoverPanelProps = {
  locale: NewsFormLocale;
  hasCover: boolean;
  coverImageUrl: string | null;
  coverMediaId: string | null;
  media: NewsMediaDto[];
  readOnly: boolean;
  busy: boolean;
  onAltTextChange?: (mediaId: string, locale: NewsFormLocale, value: string) => void;
};

export function NewsInspectorCoverPanel({
  locale,
  hasCover,
  coverImageUrl,
  coverMediaId,
  media,
  readOnly,
  busy,
  onAltTextChange,
}: NewsInspectorCoverPanelProps) {
  const t = useTranslations('news');
  const cover = coverMediaId ? media.find((m) => m.id === coverMediaId) : media.find((m) => m.kind === 'cover');
  const altComplete = coverAltTextForLocale(media, locale);

  return (
    <div className={styles.root}>
      <div className={styles.row}>
        {hasCover && coverImageUrl ? (
          <div className={styles.thumb}>
            <Image src={coverImageUrl} alt="" fill className={styles.thumbImage} sizes="4rem" unoptimized />
          </div>
        ) : (
          <div className={styles.thumbPlaceholder} aria-hidden />
        )}
        <div className={styles.copy}>
          <p className={styles.title}>{t('inspector.coverTitle')}</p>
          <p className={hasCover ? styles.statusOk : styles.statusWarn}>
            {hasCover ? t('inspector.coverPresent') : t('inspector.coverMissing')}
          </p>
          <p className={styles.hint}>{t('inspector.coverHeroHint')}</p>
        </div>
      </div>

      {hasCover && cover && !readOnly && onAltTextChange ? (
        <Input
          label={t('form.altText', { locale: locale.toUpperCase() })}
          value={cover.altText?.[locale] ?? ''}
          onChange={(e) => onAltTextChange(cover.id, locale, e.target.value)}
          disabled={busy}
          helperText={altComplete ? t('inspector.coverAltOk') : t('inspector.coverAltMissing')}
        />
      ) : null}
    </div>
  );
}
