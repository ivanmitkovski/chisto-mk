'use client';

import { MAX_GALLERY_ITEMS, MIN_GALLERY_ITEMS } from '@chisto/news-content';
import Image from 'next/image';
import { useCallback, useRef, useState, type DragEvent } from 'react';
import { useTranslations } from 'next-intl';
import { Button, Icon, Spinner, ToolbarSelect } from '@/components/ui';
import type { NewsBodyBlock, NewsMediaDto } from '../news-api-types';
import { NEWS_MEDIA_ACCEPT } from '../lib/news-media-validation';
import { useNewsMediaGuidanceText } from '../hooks/use-news-media-guidance';
import styles from './news-gallery-block-editor.module.css';

type GalleryBlock = Extract<NewsBodyBlock, { type: 'gallery' }>;

type NewsGalleryBlockEditorProps = {
  block: GalleryBlock;
  media: NewsMediaDto[];
  readOnly: boolean;
  busy?: boolean | undefined;
  uploadBusySlotIndex?: number | null | undefined;
  uploadError?: string | null | undefined;
  onChange: (block: GalleryBlock) => void;
  onAddFromLibrary?: ((mediaId: string) => void) | undefined;
  onUploadForSlot?: ((itemIndex: number, file: File) => void) | undefined;
};

type GallerySlotProps = {
  item: GalleryBlock['items'][number];
  index: number;
  total: number;
  attached: NewsMediaDto | undefined;
  readOnly: boolean;
  busy: boolean;
  uploadBusy: boolean;
  inlineImages: NewsMediaDto[];
  onUpdate: (patch: Partial<GalleryBlock['items'][number]>) => void;
  onRemove: () => void;
  onMove: (direction: -1 | 1) => void;
  onUpload: (file: File) => void;
  canRemove: boolean;
  canMoveLeft: boolean;
  canMoveRight: boolean;
};

function GallerySlot({
  item,
  index,
  total,
  attached,
  readOnly,
  busy,
  uploadBusy,
  inlineImages,
  onUpdate,
  onRemove,
  onMove,
  onUpload,
  canRemove,
  canMoveLeft,
  canMoveRight,
}: GallerySlotProps) {
  const t = useTranslations('news');
  const inputRef = useRef<HTMLInputElement>(null);
  const [dragOver, setDragOver] = useState(false);
  const hasImage = Boolean(attached?.url);

  const pickFile = useCallback(
    (file: File | undefined) => {
      if (!file || readOnly || busy || uploadBusy) return;
      onUpload(file);
    },
    [busy, onUpload, readOnly, uploadBusy],
  );

  const onDrop = useCallback(
    (event: DragEvent) => {
      event.preventDefault();
      setDragOver(false);
      if (readOnly || busy || uploadBusy) return;
      pickFile(event.dataTransfer.files?.[0]);
    },
    [busy, pickFile, readOnly, uploadBusy],
  );

  const libraryOptions = [
    { value: '', label: t('form.pickFromLibrary') },
    ...inlineImages.map((m) => ({
      value: m.id,
      label: m.fileName ?? m.id.slice(0, 8),
    })),
  ];

  return (
    <li
      className={`${styles.slide} ${styles.slideDocument}`}
      aria-label={t('form.gallerySlideAria', { index: index + 1, total })}
    >
      <div
        className={[
          styles.frame,
          hasImage ? styles.frameFilled : styles.frameEmpty,
          dragOver ? styles.frameDragOver : '',
          uploadBusy ? styles.frameUploading : '',
        ]
          .filter(Boolean)
          .join(' ')}
        onDragOver={(event) => {
          event.preventDefault();
          if (!readOnly && !busy && !uploadBusy) setDragOver(true);
        }}
        onDragLeave={() => setDragOver(false)}
        onDrop={onDrop}
      >
        {hasImage && attached?.url ? (
          <Image src={attached.url} alt="" fill className={styles.frameImage} unoptimized />
        ) : (
          <div className={styles.emptyState}>
            {uploadBusy ? (
              <Spinner size="sm" />
            ) : (
              <>
                <Icon name="image" size={20} strokeWidth={1.75} aria-hidden />
                <span className={styles.emptyLabel}>{t('form.galleryAddPhoto')}</span>
                <span className={styles.emptyHint}>{t('form.galleryDropHint')}</span>
              </>
            )}
          </div>
        )}

        <span className={styles.slideBadge} aria-hidden>
          {index + 1}
        </span>

        {!readOnly ? (
          <>
            <input
              ref={inputRef}
              type="file"
              accept={NEWS_MEDIA_ACCEPT.inline_image}
              className={styles.fileInput}
              disabled={busy || uploadBusy}
              tabIndex={-1}
              aria-hidden
              onChange={(event) => {
                pickFile(event.target.files?.[0]);
                event.target.value = '';
              }}
            />
            {hasImage ? (
              <div className={styles.frameToolbar}>
                <button
                  type="button"
                  className={styles.toolbarBtn}
                  disabled={busy || !canMoveLeft}
                  onClick={() => onMove(-1)}
                  aria-label={t('form.galleryMoveSlideLeft')}
                >
                  <Icon name="chevron-left" size={14} strokeWidth={2} aria-hidden />
                </button>
                <button
                  type="button"
                  className={styles.toolbarBtn}
                  disabled={busy || !canMoveRight}
                  onClick={() => onMove(1)}
                  aria-label={t('form.galleryMoveSlideRight')}
                >
                  <Icon name="chevron-right" size={14} strokeWidth={2} aria-hidden />
                </button>
                <button
                  type="button"
                  className={styles.toolbarBtn}
                  disabled={busy || uploadBusy}
                  onClick={() => inputRef.current?.click()}
                  aria-label={t('form.galleryReplacePhoto')}
                >
                  <Icon name="image" size={14} strokeWidth={2} aria-hidden />
                </button>
                <button
                  type="button"
                  className={[styles.toolbarBtn, styles.toolbarBtnDanger].join(' ')}
                  disabled={busy || !canRemove}
                  onClick={onRemove}
                  aria-label={t('form.galleryRemoveSlide')}
                >
                  <Icon name="x" size={14} strokeWidth={2} aria-hidden />
                </button>
              </div>
            ) : (
              <button
                type="button"
                className={styles.frameTapTarget}
                disabled={busy || uploadBusy}
                onClick={() => inputRef.current?.click()}
                aria-label={t('form.galleryAddPhoto')}
              />
            )}
            {uploadBusy ? <div className={styles.uploadOverlay} aria-hidden /> : null}
          </>
        ) : null}
      </div>

      {!readOnly && inlineImages.length > 0 ? (
        <ToolbarSelect
          className={styles.librarySelect}
          options={libraryOptions}
          value={item.mediaId}
          disabled={busy || uploadBusy}
          aria-label={t('form.pickFromLibrary')}
          onChange={(event) => onUpdate({ mediaId: event.target.value })}
        />
      ) : null}

      <label className={styles.captionDocument}>
        <span className={styles.captionLabel}>{t('form.caption')}</span>
        <input
          type="text"
          className={styles.captionInputDocument}
          value={item.caption ?? ''}
          onChange={(event) => onUpdate({ caption: event.target.value })}
          disabled={readOnly || busy}
          maxLength={500}
          placeholder={t('form.caption')}
        />
      </label>
    </li>
  );
}

export function NewsGalleryBlockEditor({
  block,
  media,
  readOnly,
  busy = false,
  uploadBusySlotIndex = null,
  uploadError = null,
  onChange,
  onAddFromLibrary,
  onUploadForSlot,
}: NewsGalleryBlockEditorProps) {
  const t = useTranslations('news');
  const guidance = useNewsMediaGuidanceText();
  const inlineImages = media.filter((m) => m.kind === 'inline_image');
  const filledCount = block.items.filter((item) => item.mediaId.trim()).length;
  const atMax = block.items.length >= MAX_GALLERY_ITEMS;

  function updateItem(index: number, patch: Partial<GalleryBlock['items'][number]>) {
    const items = [...block.items];
    items[index] = { ...items[index], ...patch };
    onChange({ ...block, items });
  }

  function removeItem(index: number) {
    if (block.items.length <= MIN_GALLERY_ITEMS) return;
    onChange({ ...block, items: block.items.filter((_, i) => i !== index) });
  }

  function moveItem(index: number, direction: -1 | 1) {
    const target = index + direction;
    if (target < 0 || target >= block.items.length) return;
    const items = [...block.items];
    [items[index], items[target]] = [items[target], items[index]];
    onChange({ ...block, items });
  }

  function addEmptySlide() {
    if (atMax) return;
    onChange({ ...block, items: [...block.items, { mediaId: '' }] });
  }

  const rootClass = `${styles.root} ${styles.rootDocument}`;

  return (
    <div className={rootClass}>
      {!readOnly ? (
        <details className={styles.guidancePanel}>
          <summary className={styles.guidanceSummary}>
            <Icon name="info" size={14} strokeWidth={2} aria-hidden />
            <span>{t('form.galleryImageGuidanceTitle')}</span>
          </summary>
          <div className={styles.guidanceBody}>
            <p>{guidance('galleryImage')}</p>
            <p>{t('form.galleryHint')}</p>
          </div>
        </details>
      ) : null}

      <div className={styles.stripHeader}>
        <p className={styles.stripMeta} aria-live="polite">
          {t('form.gallerySlideCount', { filled: filledCount, total: block.items.length })}
        </p>
        {filledCount < MIN_GALLERY_ITEMS && !readOnly ? (
          <p className={styles.stripWarning}>{t('form.galleryMinSlidesHint')}</p>
        ) : null}
      </div>

      <ul className={styles.filmstrip} aria-label={t('form.gallerySlidesAria')}>
        {block.items.map((item, index) => {
          const attached = media.find((m) => m.id === item.mediaId);
          return (
            <GallerySlot
              key={`${block.id}-gallery-${index}`}
              item={item}
              index={index}
              total={block.items.length}
              attached={attached}
              readOnly={readOnly}
              busy={busy}
              uploadBusy={uploadBusySlotIndex === index}
              inlineImages={inlineImages}
              onUpdate={(patch) => updateItem(index, patch)}
              onRemove={() => removeItem(index)}
              onMove={(direction) => moveItem(index, direction)}
              onUpload={(file) => onUploadForSlot?.(index, file)}
              canRemove={block.items.length > MIN_GALLERY_ITEMS}
              canMoveLeft={index > 0}
              canMoveRight={index < block.items.length - 1}
            />
          );
        })}
      </ul>

      {uploadError ? (
        <p className={styles.uploadError} role="alert">
          {uploadError}
        </p>
      ) : null}

      {!readOnly ? (
        <div className={styles.footer}>
          <Button
            type="button"
            variant="ghost"
            size="sm"
            className={styles.addSlideBtn}
            disabled={busy || atMax}
            onClick={addEmptySlide}
          >
            <Icon name="plus" size={14} strokeWidth={2} aria-hidden />
            {t('form.addGalleryImage')}
          </Button>
          {onAddFromLibrary && inlineImages.length > 0 ? (
            <ToolbarSelect
              className={styles.footerLibrarySelect}
              options={[
                { value: '', label: t('form.addFromLibrary') },
                ...inlineImages.map((m) => ({
                  value: m.id,
                  label: m.fileName ?? m.id.slice(0, 8),
                })),
              ]}
              value=""
              disabled={busy || atMax}
              aria-label={t('form.addFromLibrary')}
              onChange={(event) => {
                const id = event.target.value;
                if (id) onAddFromLibrary(id);
              }}
            />
          ) : null}
          {atMax ? <span className={styles.limitHint}>{t('form.galleryMaxSlides')}</span> : null}
        </div>
      ) : null}
    </div>
  );
}
