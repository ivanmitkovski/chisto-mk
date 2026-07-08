'use client';

import { Icon } from '@/components/ui';
import type { NewsBodyBlock, NewsMediaDto } from '../news-api-types';
import { NewsBlockDragSnapshot } from './news-block-drag-snapshot';
import styles from './news-block-list.module.css';

type NewsBlockDragOverlayRowProps = {
  block: NewsBodyBlock;
  media: NewsMediaDto[];
  width?: number | undefined;
  height?: number | undefined;
};

export function NewsBlockDragOverlayRow({
  block,
  media,
  width,
  height,
}: NewsBlockDragOverlayRowProps) {
  const wrapClass = `${styles.rowWrap} ${styles.rowWrapDocument}`;
  const rowClass = `${styles.row} ${styles.rowDocument} ${styles.rowDragging}`;

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
          className={styles.dragHandleDocument}
          aria-hidden
        >
          <Icon name="arrow-up-down" size={14} strokeWidth={2} />
        </span>
        <div className={styles.rowContent}>
          <NewsBlockDragSnapshot block={block} media={media} />
        </div>
        <span
          className={styles.removeBtnDocument}
          aria-hidden
        />
      </div>
    </div>
  );
}
