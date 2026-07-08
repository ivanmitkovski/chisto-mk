'use client';

import Image from 'next/image';
import { useTranslations } from 'next-intl';
import { sanitizeInlineHtml } from '@chisto/news-content';
import {
  blockAttachedMedia,
  blockGalleryMedia,
  blockPreviewText,
} from '../lib/news-block-display';
import type { NewsBodyBlock, NewsMediaDto } from '../news-api-types';
import styles from './news-block-drag-snapshot.module.css';

type NewsBlockDragSnapshotProps = {
  block: NewsBodyBlock;
  media: NewsMediaDto[];
};

function paragraphHtml(block: NewsBodyBlock): string {
  if (block.type !== 'paragraph') return '';
  if (block.html?.trim()) return sanitizeInlineHtml(block.html);
  if (block.text.trim()) return `<p>${block.text.replace(/\n/g, '<br>')}</p>`;
  return '';
}

export function NewsBlockDragSnapshot({ block, media }: NewsBlockDragSnapshotProps) {
  const t = useTranslations('news');
  const preview = blockPreviewText(block);
  const attached = blockAttachedMedia(block, media);
  const galleryItems = blockGalleryMedia(block, media);
  const visibleGallery = galleryItems.slice(0, 4);
  const galleryOverflow = Math.max(0, galleryItems.length - visibleGallery.length);

  const snapshotClass = `${styles.snapshot} ${styles.snapshotDocument}`;

  return <div className={snapshotClass}>{renderBody()}</div>;

  function renderBody() {
    switch (block.type) {
      case 'paragraph': {
        const html = paragraphHtml(block);
        if (!html) {
          return <p className={styles.empty}>{t('drag.emptyPreview')}</p>;
        }
        return (
          <div
            className={styles.paragraphDocument}
            dangerouslySetInnerHTML={{ __html: html }}
          />
        );
      }
      case 'heading':
        if (!block.text.trim()) {
          return <p className={styles.empty}>{t('drag.emptyPreview')}</p>;
        }
        if (block.level === 3) {
          return <p className={styles.heading3Document}>{block.text}</p>;
        }
        return <p className={styles.heading2Document}>{block.text}</p>;
      case 'list': {
        const items = block.items.map((item) => item.trim()).filter(Boolean);
        if (items.length === 0) {
          return <p className={styles.empty}>{t('drag.emptyPreview')}</p>;
        }
        const ListTag = block.ordered ? 'ol' : 'ul';
        return (
          <ListTag className={styles.listDocument}>
            {items.map((item, index) => (
              <li key={`${index}-${item.slice(0, 24)}`} className={styles.listItem}>
                {item}
              </li>
            ))}
          </ListTag>
        );
      }
      case 'image':
      case 'video':
        return (
          <div className={styles.mediaWrap}>
            {attached?.url && block.type === 'image' ? (
              <div className={styles.mediaThumb}>
                <Image
                  src={attached.url}
                  alt=""
                  fill
                  sizes="24rem"
                  className={styles.mediaThumbImage}
                />
              </div>
            ) : attached?.url && block.type === 'video' ? (
              <video
                src={attached.url}
                className={styles.mediaVideo}
                muted
                playsInline
                preload="metadata"
              />
            ) : (
              <p className={styles.empty}>{attached?.fileName ?? t('drag.emptyPreview')}</p>
            )}
            {preview ? <p className={styles.caption}>{preview}</p> : null}
          </div>
        );
      case 'gallery':
        if (visibleGallery.length === 0) {
          return <p className={styles.empty}>{t('drag.emptyPreview')}</p>;
        }
        return (
          <div className={styles.galleryStrip}>
            {visibleGallery.map((item) =>
              item.url ? (
                <div key={item.id} className={styles.gallerySlot}>
                  <Image src={item.url} alt="" fill sizes="4.5rem" className={styles.mediaThumbImage} />
                </div>
              ) : null,
            )}
            {galleryOverflow > 0 ? (
              <span className={styles.galleryMore}>+{galleryOverflow}</span>
            ) : null}
          </div>
        );
      case 'html':
        if (!preview) {
          return <p className={styles.empty}>{t('drag.emptyPreview')}</p>;
        }
        return <p className={styles.htmlPreview}>{preview}</p>;
      default:
        return preview ? (
          <p className={styles.paragraphDocument}>{preview}</p>
        ) : (
          <p className={styles.empty}>{t('drag.emptyPreview')}</p>
        );
    }
  }
}
