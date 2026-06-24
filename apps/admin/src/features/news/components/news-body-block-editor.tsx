'use client';

import Image from 'next/image';
import { useTranslations } from 'next-intl';
import { Button } from '@/components/ui';
import type { NewsBodyBlock, NewsMediaDto } from '../news-api-types';
import styles from './news-body-block-editor.module.css';

type NewsBodyBlockEditorProps = {
  block: NewsBodyBlock;
  index: number;
  total: number;
  media: NewsMediaDto[];
  readOnly: boolean;
  busy: boolean;
  onChange: (block: NewsBodyBlock) => void;
  onRemove: () => void;
  onMoveUp: () => void;
  onMoveDown: () => void;
};

function mediaForBlock(block: NewsBodyBlock, media: NewsMediaDto[]): NewsMediaDto | undefined {
  if (block.type === 'paragraph') return undefined;
  return media.find((m) => m.id === block.mediaId);
}

export function NewsBodyBlockEditor({
  block,
  index,
  total,
  media,
  readOnly,
  busy,
  onChange,
  onRemove,
  onMoveUp,
  onMoveDown,
}: NewsBodyBlockEditorProps) {
  const t = useTranslations('news');
  const attached = mediaForBlock(block, media);

  return (
    <div className={styles.block}>
      <div className={styles.blockHeader}>
        <span className={styles.blockType}>
          {block.type === 'paragraph'
            ? t('form.blockParagraph')
            : block.type === 'image'
              ? t('form.blockImage')
              : t('form.blockVideo')}
        </span>
        {!readOnly ? (
          <div className={styles.blockActions}>
            <Button type="button" variant="ghost" size="sm" disabled={busy || index === 0} onClick={onMoveUp}>
              ↑
            </Button>
            <Button
              type="button"
              variant="ghost"
              size="sm"
              disabled={busy || index >= total - 1}
              onClick={onMoveDown}
            >
              ↓
            </Button>
            <Button type="button" variant="ghost" size="sm" disabled={busy} onClick={onRemove}>
              {t('form.removeBlock')}
            </Button>
          </div>
        ) : null}
      </div>

      {block.type === 'paragraph' ? (
        <>
          <textarea
            className={styles.textarea}
            rows={4}
            value={block.text}
            onChange={(e) => onChange({ type: 'paragraph', text: e.target.value })}
            disabled={busy || readOnly}
            maxLength={10_000}
          />
          <span className={styles.charCount}>{block.text.length} / 10000</span>
        </>
      ) : (
        <div className={styles.mediaBlock}>
          {attached?.url ? (
            block.type === 'image' ? (
              <div className={styles.preview}>
                <Image src={attached.url} alt="" fill className={styles.previewImage} unoptimized />
              </div>
            ) : (
              <video src={attached.url} controls className={styles.videoPreview} />
            )
          ) : (
            <p className={styles.mediaRef}>{block.mediaId}</p>
          )}
          <label className={styles.captionField}>
            <span>{t('form.caption')}</span>
            <input
              type="text"
              value={block.caption ?? ''}
              onChange={(e) => onChange({ ...block, caption: e.target.value })}
              disabled={busy || readOnly}
            />
          </label>
        </div>
      )}
    </div>
  );
}
