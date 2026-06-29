'use client';

import { Icon } from '@/components/ui';
import type { NewsBodyBlock, NewsMediaDto } from '../news-api-types';
import { NewsBlockDragSnapshot } from './news-block-drag-snapshot';
import styles from './news-block-list.module.css';

type NewsBlockDragOverlayRowProps = {
  block: NewsBodyBlock;
  media: NewsMediaDto[];
  documentMode?: boolean;
  width?: number | undefined;
  height?: number | undefined;
};

export function NewsBlockDragOverlayRow({
  block,
  media,
  documentMode = false,
  width,
  height,
}: NewsBlockDragOverlayRowProps) {
  const wrapClass = [styles.rowWrap, documentMode ? styles.rowWrapDocument : ''].filter(Boolean).join(' ');
  const rowClass = [styles.row, documentMode ? styles.rowDocument : '', styles.rowDragging]
    .filter(Boolean)
    .join(' ');

  const frozenSize =
    width || height
      ? {
          ...(width ? { width, maxWidth: width } : {}),
          ...(height ? { height, minHeight: height } : {}),
        }
      : undefined;

  return (
    <div className={wrapClass} style={frozenSize}>
      <div className={rowClass}>
        <span
          className={documentMode ? styles.dragHandleDocument : styles.dragHandle}
          aria-hidden
        >
          <Icon name="arrow-up-down" size={14} strokeWidth={2} />
        </span>
        <div className={styles.rowContent}>
          <NewsBlockDragSnapshot block={block} media={media} documentMode={documentMode} />
        </div>
        <span
          className={documentMode ? styles.removeBtnDocument : styles.removeBtn}
          aria-hidden
        />
      </div>
    </div>
  );
}
