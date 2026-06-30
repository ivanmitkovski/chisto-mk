'use client';

import Image from 'next/image';
import { ConfirmDialog, Icon } from '@/components/ui';
import { useStaticNewsTranslations } from '../hooks/use-static-news-translations';
import {
  blockAttachedMedia,
  blockGalleryItemCount,
  blockGalleryMedia,
  blockPreviewText,
  blockTypeLabel,
} from '../lib/news-block-display';
import { blockOptionByType, type BlockInsertType } from '../lib/news-block-insert-config';
import type { NewsBodyBlock, NewsMediaDto } from '../news-api-types';
import styles from './news-block-remove-dialog.module.css';

type NewsBlockRemoveDialogProps = {
  open: boolean;
  block: NewsBodyBlock | null;
  index: number;
  total: number;
  media: NewsMediaDto[];
  onConfirm: () => void;
  onClose: () => void;
};

function toneClass(tone: 'text' | 'media' | 'advanced'): string {
  switch (tone) {
    case 'media':
      return styles.previewIconMedia;
    case 'advanced':
      return styles.previewIconAdvanced;
    default:
      return styles.previewIconText;
  }
}

function BlockRemovePreview({
  block,
  index,
  total,
  media,
}: {
  block: NewsBodyBlock;
  index: number;
  total: number;
  media: NewsMediaDto[];
}) {
  const t = useStaticNewsTranslations();
  const option = blockOptionByType(block.type as BlockInsertType);
  const preview = blockPreviewText(block);
  const label = blockTypeLabel(block, t);
  const attached = blockAttachedMedia(block, media);
  const galleryItems = blockGalleryMedia(block, media);
  const galleryCount = blockGalleryItemCount(block);
  const visibleGallery = galleryItems.slice(0, 4);
  const galleryOverflow = Math.max(0, galleryCount - visibleGallery.length);

  return (
    <div className={styles.stack}>
      <p className={styles.position}>
        {t('confirm.removeBlockPosition', { position: index + 1, total })}
      </p>

      <div className={styles.previewCard}>
        <span className={`${styles.previewIcon} ${toneClass(option.tone)}`} aria-hidden>
          <Icon name={option.icon} size={18} strokeWidth={1.75} />
        </span>
        <div className={styles.previewCopy}>
          <span className={styles.previewType}>{label}</span>
          {preview ? (
            <span className={styles.previewText}>{preview}</span>
          ) : block.type === 'gallery' && galleryCount > 0 ? (
            <span className={styles.previewText}>
              {t('confirm.removeBlockGalleryCount', { count: galleryCount })}
            </span>
          ) : attached?.fileName ? (
            <span className={styles.previewText}>{attached.fileName}</span>
          ) : (
            <span className={styles.previewEmpty}>{t('drag.emptyPreview')}</span>
          )}

          {attached?.url && block.type === 'image' ? (
            <div className={styles.mediaThumb}>
              <Image src={attached.url} alt="" fill sizes="12rem" />
            </div>
          ) : attached?.url && block.type === 'video' ? (
            <video src={attached.url} className={styles.mediaThumb} muted playsInline preload="metadata" />
          ) : null}

          {block.type === 'gallery' && visibleGallery.length > 0 ? (
            <div className={styles.galleryStrip} aria-hidden>
              {visibleGallery.map((item) =>
                item.url ? (
                  <div key={item.id} className={styles.galleryThumb}>
                    <Image src={item.url} alt="" fill sizes="3.5rem" />
                  </div>
                ) : null,
              )}
              {galleryOverflow > 0 ? (
                <span className={styles.galleryMore}>+{galleryOverflow}</span>
              ) : null}
            </div>
          ) : null}
        </div>
      </div>

      <p className={styles.undoHint}>
        <span className={styles.undoHintIcon} aria-hidden>
          <Icon name="info" size={14} strokeWidth={2} />
        </span>
        <span>{t('confirm.removeBlockUndoHint')}</span>
      </p>
    </div>
  );
}

export function NewsBlockRemoveDialog({
  open,
  block,
  index,
  total,
  media,
  onConfirm,
  onClose,
}: NewsBlockRemoveDialogProps) {
  const t = useStaticNewsTranslations();

  return (
    <ConfirmDialog
      open={open && block !== null}
      tone="danger"
      title={t('confirm.removeBlockTitle')}
      cancelLabel={t('confirm.removeBlockCancel')}
      confirmLabel={t('confirm.removeBlockConfirm')}
      onConfirm={onConfirm}
      onClose={onClose}
    >
      {block ? (
        <BlockRemovePreview block={block} index={index} total={total} media={media} />
      ) : null}
    </ConfirmDialog>
  );
}
