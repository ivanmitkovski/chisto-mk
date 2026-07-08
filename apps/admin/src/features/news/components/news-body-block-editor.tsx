'use client';

import dynamic from 'next/dynamic';
import { useTranslations } from 'next-intl';
import { RichTextEditor } from '@/components/ui/rich-text-editor';
import type { NewsBodyBlock, NewsMediaDto } from '../news-api-types';
import { NewsListBlockEditor } from './news-list-block-editor';
import { NewsMediaBlockEditor } from './news-media-block-editor';
import { NewsQuoteBlockEditor } from './news-quote-block-editor';
import styles from './news-body-block-editor.module.css';

const NewsGalleryBlockEditor = dynamic(
  () => import('./news-gallery-block-editor').then((m) => ({ default: m.NewsGalleryBlockEditor })),
  { ssr: false },
);
const NewsHtmlBlockEditor = dynamic(
  () => import('./news-html-block-editor').then((m) => ({ default: m.NewsHtmlBlockEditor })),
  { ssr: false },
);
const NewsEmbedBlockEditor = dynamic(
  () => import('./news-embed-block-editor').then((m) => ({ default: m.NewsEmbedBlockEditor })),
  { ssr: false },
);

type NewsBodyBlockEditorProps = {
  block: NewsBodyBlock;
  index: number;
  media: NewsMediaDto[];
  readOnly: boolean;
  busy: boolean;
  uploadBusy?: boolean;
  uploadError?: string | null;
  localPreviewSrc?: string | null;
  autoFocus?: boolean | undefined;
  onAutoFocused?: (() => void) | undefined;
  onChange: (block: NewsBodyBlock) => void;
  /** Typing "/" in an empty paragraph opens the insert palette. */
  onSlashMenu?: (() => void) | undefined;
  onCreateBlockAfter?: (() => void) | undefined;
  onMergeWithPrevious?: (() => void) | undefined;
  onMultiParagraphPaste?: ((raw: { html: string; plain: string }) => boolean) | undefined;
  onPasteImageFile?: ((file: File) => boolean) | undefined;
  /** Enter in a heading starts a fresh paragraph below (news writing flow). */
  onInsertParagraphAfter?: (() => void) | undefined;
  /** Backspace on an empty heading removes it, like merging up in a document. */
  onRemoveSelf?: (() => void) | undefined;
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
  media,
  readOnly,
  busy,
  uploadBusy = false,
  uploadError = null,
  localPreviewSrc = null,
  autoFocus = false,
  onAutoFocused,
  onChange,
  onSlashMenu,
  onCreateBlockAfter,
  onMergeWithPrevious,
  onMultiParagraphPaste,
  onPasteImageFile,
  onInsertParagraphAfter,
  onRemoveSelf,
  onUploadForBlock,
  onReplaceForBlock,
  onUploadForGallerySlot,
  uploadGallerySlotIndex = null,
}: NewsBodyBlockEditorProps) {
  const t = useTranslations('news');
  const attached = mediaForBlock(block, media);

  return (
    <div className={styles.blockDocument}>
      {block.type === 'paragraph' ? (
        <RichTextEditor
          key={block.id}
          variant="document"
          documentBlockId={block.id ?? `block-${index}`}
          documentBlockIndex={index}
          autoFocus={autoFocus}
          onAutoFocused={onAutoFocused}
          onSlashMenu={onSlashMenu}
          onCreateBlockAfter={onCreateBlockAfter}
          onMergeWithPrevious={onMergeWithPrevious}
          onMultiParagraphPaste={onMultiParagraphPaste}
          onPasteImageFile={onPasteImageFile}
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
          onChange={(html) => onChange({ ...block, html })}
        />
      ) : block.type === 'heading' ? (
        <div className={styles.headingBlockDocument}>
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
          <input
            type="text"
            className={
              block.level === 3 ? styles.headingInputDocument3 : styles.headingInputDocument2
            }
            value={block.text}
            onChange={(e) => onChange({ ...block, text: e.target.value })}
            onKeyDown={(e) => {
              if (readOnly) return;
              if (e.key === 'Enter' && !e.shiftKey && onInsertParagraphAfter) {
                e.preventDefault();
                onInsertParagraphAfter();
              }
              if (e.key === 'Backspace' && block.text === '' && onRemoveSelf) {
                e.preventDefault();
                onRemoveSelf();
              }
            }}
            disabled={readOnly}
            maxLength={200}
            placeholder={t('form.headingPlaceholder')}
            {...(autoFocus ? { autoFocus: true } : {})}
          />
        </div>
      ) : block.type === 'list' ? (
        <NewsListBlockEditor
          block={block}
          readOnly={readOnly}
          busy={busy}
          onChange={onChange}
        />
      ) : block.type === 'gallery' ? (
        <NewsGalleryBlockEditor
          block={block}
          media={media}
          readOnly={readOnly}
          busy={busy}
          uploadBusySlotIndex={uploadGallerySlotIndex}
          uploadError={uploadError}
          onChange={onChange}
          onAddFromLibrary={(mediaId) =>
            onChange({ ...block, items: [...block.items, { mediaId }] })
          }
          onUploadForSlot={onUploadForGallerySlot}
        />
      ) : block.type === 'quote' ? (
        <NewsQuoteBlockEditor
          block={block}
          readOnly={readOnly}
          autoFocus={autoFocus}
          onChange={onChange}
        />
      ) : block.type === 'divider' ? (
        <hr className={styles.dividerDocument} aria-label={t('form.blockDivider')} />
      ) : block.type === 'embed' ? (
        <NewsEmbedBlockEditor
          block={block}
          readOnly={readOnly}
          autoFocus={autoFocus}
          onChange={onChange}
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
          onChange={onChange}
          onUpload={onReplaceForBlock ?? onUploadForBlock}
        />
      ) : (
        <p className={styles.mediaRef}>{t('form.noMedia')}</p>
      )}
    </div>
  );
}
