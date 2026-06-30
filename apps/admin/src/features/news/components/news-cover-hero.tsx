'use client';

import Image from 'next/image';
import { ImagePlus } from 'lucide-react';
import { useCallback, useId, useState, type DragEvent } from 'react';
import { useTranslations } from 'next-intl';
import { Spinner } from '@/components/ui';
import { useNewsMediaGuidanceText } from '../hooks/use-news-media-guidance';
import { NEWS_MEDIA_ACCEPT } from '../lib/news-media-validation';
import styles from './news-cover-hero.module.css';

type NewsCoverHeroProps = {
  coverImageUrl: string | null;
  /** True when a cover media id exists (URL may still be loading). */
  coverAttached?: boolean;
  readOnly: boolean;
  uploadBusy: boolean;
  uploadError?: string | null | undefined;
  onUpload: (file: File) => void;
};

export function NewsCoverHero({
  coverImageUrl,
  coverAttached = false,
  readOnly,
  uploadBusy,
  uploadError,
  onUpload,
}: NewsCoverHeroProps) {
  const t = useTranslations('news');
  const guidance = useNewsMediaGuidanceText();
  const inputId = useId();
  const [dragOver, setDragOver] = useState(false);

  const hasCover = Boolean(coverImageUrl) || coverAttached;
  const interactive = !readOnly;
  const disabled = readOnly || uploadBusy;

  const pickFile = useCallback(
    (file: File | undefined) => {
      if (!file || disabled) return;
      onUpload(file);
    },
    [disabled, onUpload],
  );

  const onInputChange = useCallback(
    (event: React.ChangeEvent<HTMLInputElement>) => {
      pickFile(event.target.files?.[0]);
      event.target.value = '';
    },
    [pickFile],
  );

  const onDrop = useCallback(
    (event: DragEvent) => {
      event.preventDefault();
      setDragOver(false);
      if (disabled) return;
      pickFile(event.dataTransfer.files?.[0]);
    },
    [disabled, pickFile],
  );

  const frameClass = [
    styles.frame,
    hasCover ? styles.frameFilled : styles.frameEmpty,
    dragOver ? styles.frameDragOver : '',
    uploadBusy ? styles.frameBusy : '',
    uploadError ? styles.frameError : '',
  ]
    .filter(Boolean)
    .join(' ');

  const frameBody = (
    <>
      {hasCover && coverImageUrl ? (
        <>
          <Image
            src={coverImageUrl}
            alt=""
            fill
            className={styles.image}
            priority
            unoptimized
            sizes="(min-width: 896px) 896px, 100vw"
          />
          {interactive ? (
            <div className={styles.overlay} aria-hidden>
              <span className={styles.overlayLabel}>{t('form.replaceCover')}</span>
            </div>
          ) : null}
        </>
      ) : hasCover ? (
        <div className={styles.emptyState} aria-busy="true">
          <Spinner size="sm" />
        </div>
      ) : (
        <div className={styles.emptyState}>
          <div className={styles.iconWrap} aria-hidden>
            <ImagePlus className={styles.icon} strokeWidth={1.5} />
          </div>
          <p className={styles.placeholder}>{t('form.coverPlaceholder')}</p>
          <p className={styles.hint}>{guidance('cover')}</p>
          {interactive ? (
            <span className={styles.chooseButton}>{t('form.uploadCover')}</span>
          ) : null}
        </div>
      )}

      {uploadBusy ? (
        <div className={styles.busyOverlay} aria-live="polite">
          <Spinner size="sm" />
          <span className={styles.busyLabel}>{t('form.uploadCover')}</span>
        </div>
      ) : null}

      {uploadBusy ? <div className={styles.progressTrack} aria-hidden /> : null}
    </>
  );

  return (
    <section className={styles.root} aria-label={t('form.cover')}>
      {interactive ? (
        <label
          htmlFor={inputId}
          className={frameClass}
          onDragOver={(event) => {
            event.preventDefault();
            if (!disabled) setDragOver(true);
          }}
          onDragLeave={() => setDragOver(false)}
          onDrop={onDrop}
        >
          <input
            id={inputId}
            type="file"
            accept={NEWS_MEDIA_ACCEPT.cover}
            className={styles.input}
            disabled={disabled}
            onChange={onInputChange}
            tabIndex={-1}
            aria-hidden
          />
          {frameBody}
        </label>
      ) : (
        <div className={frameClass}>{frameBody}</div>
      )}

      {uploadError && !uploadBusy ? (
        <p className={styles.error} role="alert">
          {uploadError}
        </p>
      ) : null}

      {!readOnly && hasCover ? (
        <p className={styles.specLine}>{guidance('cover')}</p>
      ) : null}
    </section>
  );
}
