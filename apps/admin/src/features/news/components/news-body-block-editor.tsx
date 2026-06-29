'use client';

import { useTranslations } from 'next-intl';
import { Button, RichTextEditor } from '@/components/ui';
import type { NewsBodyBlock, NewsMediaDto } from '../news-api-types';
import { blockTypeLabel } from '../lib/news-block-display';
import { NewsGalleryBlockEditor } from './news-gallery-block-editor';
import { NewsHtmlBlockEditor } from './news-html-block-editor';
import { NewsListBlockEditor } from './news-list-block-editor';
import { NewsMediaBlockEditor } from './news-media-block-editor';
import styles from './news-body-block-editor.module.css';

type NewsBodyBlockEditorProps = {
  block: NewsBodyBlock;
  index: number;
  total: number;
  media: NewsMediaDto[];
  readOnly: boolean;
  busy: boolean;
  uploadBusy?: boolean;
  uploadError?: string | null;
  localPreviewSrc?: string | null;
  variant?: 'classic' | 'document';
  onChange: (block: NewsBodyBlock) => void;
  onRemove: () => void;
  onMoveUp: () => void;
  onMoveDown: () => void;
  onUploadForBlock?: (file: File) => void;
  onReplaceForBlock?: (file: File) => void;
  onUploadForGallerySlot?: (itemIndex: number, file: File) => void;
  uploadGallerySlotIndex?: number | null;
};

function mediaForBlock(block: NewsBodyBlock, media: NewsMediaDto[]): NewsMediaDto | undefined {
  if (block.type === 'image' || block.type === 'video') {
    return media.find((m) => m.id === block.mediaId);
  }
  return undefined;
}

export function NewsBodyBlockEditor({
  block,
  index,
  total,
  media,
  readOnly,
  busy,
  uploadBusy = false,
  uploadError = null,
  localPreviewSrc = null,
  variant = 'classic',
  onChange,
  onRemove,
  onMoveUp,
  onMoveDown,
  onUploadForBlock,
  onReplaceForBlock,
  onUploadForGallerySlot,
  uploadGallerySlotIndex = null,
}: NewsBodyBlockEditorProps) {
  const t = useTranslations('news');
  const attached = mediaForBlock(block, media);

  return (
    <div className={variant === 'document' ? styles.blockDocument : styles.block}>
      {variant === 'classic' ? (
      <div className={styles.blockHeader}>
        <span className={styles.blockType}>{blockTypeLabel(block, t)}</span>
        {!readOnly ? (
          <div className={styles.blockActions}>
            <Button
              type="button"
              variant="ghost"
              size="sm"
              disabled={busy || index === 0}
              onClick={onMoveUp}
              aria-label={t('form.moveBlockUp')}
            >
              ↑
            </Button>
            <Button
              type="button"
              variant="ghost"
              size="sm"
              disabled={busy || index >= total - 1}
              onClick={onMoveDown}
              aria-label={t('form.moveBlockDown')}
            >
              ↓
            </Button>
            <Button type="button" variant="ghost" size="sm" disabled={busy} onClick={onRemove}>
              {t('form.removeBlock')}
            </Button>
          </div>
        ) : null}
      </div>
      ) : null}

      {block.type === 'paragraph' ? (
        <RichTextEditor
          key={block.id}
          variant={variant === 'document' ? 'document' : 'default'}
          documentBlockId={block.id ?? `block-${index}`}
          documentBlockIndex={index}
          value={{ text: block.text, html: block.html }}
          onChange={(next) => {
            const nextBlock = { ...block, text: next.text };
            if (next.html) {
              nextBlock.html = next.html;
            } else {
              delete nextBlock.html;
            }
            onChange(nextBlock);
          }}
          disabled={readOnly}
        />
      ) : block.type === 'html' ? (
        <NewsHtmlBlockEditor
          html={block.html}
          readOnly={readOnly}
          busy={busy}
          variant={variant}
          onChange={(html) => onChange({ ...block, html })}
        />
      ) : block.type === 'heading' ? (
        <div className={variant === 'document' ? styles.headingBlockDocument : styles.headingBlock}>
          {variant === 'document' ? (
            <div className={styles.headingMeta}>
              <select
                className={styles.headingLevelSelect}
                value={block.level}
                onChange={(e) =>
                  onChange({ ...block, level: Number(e.target.value) as 2 | 3 })
                }
                disabled={readOnly}
                aria-label={t('form.headingLevel')}
              >
                <option value={2}>H2</option>
                <option value={3}>H3</option>
              </select>
            </div>
          ) : (
            <label className={styles.captionField}>
              <span>{t('form.headingLevel')}</span>
              <select
                value={block.level}
                onChange={(e) =>
                  onChange({ ...block, level: Number(e.target.value) as 2 | 3 })
                }
                disabled={readOnly}
              >
                <option value={2}>H2</option>
                <option value={3}>H3</option>
              </select>
            </label>
          )}
          <input
            type="text"
            className={
              variant === 'document'
                ? block.level === 3
                  ? styles.headingInputDocument3
                  : styles.headingInputDocument2
                : styles.headingInput
            }
            value={block.text}
            onChange={(e) => onChange({ ...block, text: e.target.value })}
            disabled={readOnly}
            maxLength={200}
            placeholder={t('form.headingPlaceholder')}
          />
        </div>
      ) : block.type === 'list' ? (
        <NewsListBlockEditor
          block={block}
          readOnly={readOnly}
          busy={busy}
          variant={variant}
          onChange={onChange}
        />
      ) : block.type === 'gallery' ? (
        <NewsGalleryBlockEditor
          block={block}
          media={media}
          readOnly={readOnly}
          busy={busy}
          variant={variant}
          uploadBusySlotIndex={uploadGallerySlotIndex}
          uploadError={uploadError}
          onChange={onChange}
          onAddFromLibrary={(mediaId) =>
            onChange({ ...block, items: [...block.items, { mediaId }] })
          }
          onUploadForSlot={onUploadForGallerySlot}
        />
      ) : block.type === 'image' || block.type === 'video' ? (
        <NewsMediaBlockEditor
          block={block}
          attached={attached}
          readOnly={readOnly}
          busy={busy}
          uploadBusy={uploadBusy}
          uploadError={uploadError}
          localPreviewSrc={localPreviewSrc}
          variant={variant}
          onChange={onChange}
          onUpload={onReplaceForBlock ?? onUploadForBlock}
        />
      ) : (
        <p className={styles.mediaRef}>{t('form.noMedia')}</p>
      )}
    </div>
  );
}
