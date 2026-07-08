'use client';

import Image from 'next/image';
import { useCallback, useId, useRef, useState, type DragEvent } from 'react';
import { useTranslations } from 'next-intl';
import { Button, Icon, Spinner } from '@/components/ui';
import type { NewsBodyBlock, NewsMediaDto } from '../news-api-types';
import { useNewsMediaGuidanceText } from '../hooks/use-news-media-guidance';
import { NEWS_MEDIA_ACCEPT } from '../lib/news-media-validation';
import { NewsVideoPreview } from './news-video-preview';
import styles from './news-media-block-editor.module.css';

type ImageBlock = Extract<NewsBodyBlock, { type: 'image' }>;
type VideoBlock = Extract<NewsBodyBlock, { type: 'video' }>;
type MediaBlock = ImageBlock | VideoBlock;

type NewsMediaBlockEditorProps = {
  block: MediaBlock;
  attached: NewsMediaDto | undefined;
  readOnly: boolean;
  busy: boolean;
  uploadBusy: boolean;
  uploadError?: string | null | undefined;
  localPreviewSrc?: string | null | undefined;
  onChange: (block: MediaBlock) => void;
  onUpload?: ((file: File) => void) | undefined;
};

export function NewsMediaBlockEditor({
  block,
  attached,
  readOnly,
  busy,
  uploadBusy,
  uploadError = null,
  localPreviewSrc = null,
  onChange,
  onUpload,
}: NewsMediaBlockEditorProps) {
  const t = useTranslations('news');
  const guidance = useNewsMediaGuidanceText();
  const inputId = useId();
  const inputRef = useRef<HTMLInputElement>(null);
  const [dragOver, setDragOver] = useState(false);
  const isVideo = block.type === 'video';
  const hasMedia = Boolean(attached?.url) || Boolean(localPreviewSrc);
  const accept = isVideo ? NEWS_MEDIA_ACCEPT.inline_video : NEWS_MEDIA_ACCEPT.inline_image;
  const guidanceText = isVideo ? guidance('video') : guidance('inlineImage');
  const disabled = readOnly || busy || uploadBusy;

  const pickFile = useCallback(
    (file: File | undefined) => {
      if (!file || disabled || !onUpload) return;
      onUpload(file);
    },
    [disabled, onUpload],
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

  const rootClass = `${styles.root} ${styles.rootDocument}`;

  return (
    <div className={rootClass}>
      {hasMedia && (attached?.url || localPreviewSrc) ? (
        <div className={styles.previewWrap}>
          {isVideo ? (
            <NewsVideoPreview
              src={attached?.url ?? localPreviewSrc ?? ''}
              mimeType={attached?.mimeType ?? null}
              localPreviewSrc={localPreviewSrc}
              playbackErrorLabel={t('form.videoPlaybackError')}
              frameClassName={styles.videoFrameDocument}
            />
          ) : attached?.url ? (
            <div className={styles.imageFrameDocument}>
              <Image src={attached.url} alt="" fill className={styles.image} unoptimized />
            </div>
          ) : null}
          {!readOnly && onUpload ? (
            <div className={styles.previewToolbar}>
              <Button
                type="button"
                variant="outline"
                size="sm"
                disabled={disabled}
                onClick={() => inputRef.current?.click()}
              >
                <Icon name="image" size={14} strokeWidth={2} aria-hidden />
                {t('form.replaceMedia')}
              </Button>
            </div>
          ) : null}
        </div>
      ) : (
        <div
          className={[
            styles.dropZone,
            dragOver ? styles.dropZoneDragOver : '',
            uploadBusy ? styles.dropZoneBusy : '',
            uploadError ? styles.dropZoneError : '',
          ]
            .filter(Boolean)
            .join(' ')}
          onDragOver={(event) => {
            event.preventDefault();
            if (!disabled) setDragOver(true);
          }}
          onDragLeave={() => setDragOver(false)}
          onDrop={onDrop}
        >
          {uploadBusy ? (
            <Spinner size="sm" />
          ) : (
            <>
              <Icon name={isVideo ? 'video' : 'image'} size={22} strokeWidth={1.75} aria-hidden />
              <p className={styles.dropTitle}>
                {isVideo ? t('form.addVideo') : t('form.addImage')}
              </p>
              <p className={styles.dropHint}>{guidanceText}</p>
              <p className={styles.dropAction}>
                {isVideo ? t('toolbar.mediaBlockVideoUploadHint') : t('toolbar.mediaBlockImageUploadHint')}
              </p>
            </>
          )}
          {!readOnly && onUpload ? (
            <button
              type="button"
              className={styles.dropTapTarget}
              disabled={disabled}
              onClick={() => inputRef.current?.click()}
              aria-label={isVideo ? t('form.addVideo') : t('form.addImage')}
            />
          ) : null}
        </div>
      )}

      {!readOnly && onUpload ? (
        <input
          ref={inputRef}
          id={inputId}
          type="file"
          accept={accept}
          className={styles.fileInput}
          disabled={disabled}
          tabIndex={-1}
          aria-hidden
          onChange={(event) => {
            pickFile(event.target.files?.[0]);
            event.target.value = '';
          }}
        />
      ) : null}

      {uploadError ? (
        <p className={styles.uploadError} role="alert">
          {uploadError}
        </p>
      ) : null}

      <label className={styles.captionDocument}>
        <span className={styles.captionLabel}>{t('form.caption')}</span>
        <input
          type="text"
          className={styles.captionInputDocument}
          value={block.caption ?? ''}
          onChange={(event) => onChange({ ...block, caption: event.target.value })}
          disabled={readOnly || busy}
          maxLength={500}
          placeholder={t('form.caption')}
        />
      </label>
    </div>
  );
}
