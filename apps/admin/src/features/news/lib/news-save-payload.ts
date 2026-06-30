import {
  MIN_GALLERY_ITEMS,
  sanitizeHtmlBlock,
  sanitizeInlineHtml,
  stripEmptyBlocks,
  stripHtmlToPlainText,
  type NewsBodyBlock,
} from '@chisto/news-content';
import type { NewsPostFormValues } from '../types';
import { NEWS_LOCALES } from '../types';

function paragraphHtmlIsRedundant(text: string, sanitized: string): boolean {
  const htmlPlain = stripHtmlToPlainText(sanitized).trim();
  if (htmlPlain !== text.trim()) return false;
  const inner = sanitized.replace(/^<p>/i, '').replace(/<\/p>$/i, '').trim();
  return !inner.includes('<');
}

function normalizeParagraphBlock(
  block: Extract<NewsBodyBlock, { type: 'paragraph' }>,
): Extract<NewsBodyBlock, { type: 'paragraph' }> {
  const text = block.text?.trim() ?? '';
  const html = block.html?.trim();
  if (!html) {
    return text ? { type: 'paragraph', text } : { type: 'paragraph', text: '' };
  }

  const sanitized = sanitizeInlineHtml(html);
  const htmlPlain = stripHtmlToPlainText(sanitized).trim();

  if (!sanitized || !htmlPlain) {
    return { type: 'paragraph', text };
  }

  if (paragraphHtmlIsRedundant(text, sanitized)) {
    return { type: 'paragraph', text: htmlPlain };
  }

  return { type: 'paragraph', text: text || htmlPlain, html: sanitized };
}

/** Strips client-only block ids and normalizes body blocks for API + dirty comparison. */
export function normalizeBodyBlockForSave(block: NewsBodyBlock): NewsBodyBlock {
  switch (block.type) {
    case 'paragraph':
      return normalizeParagraphBlock(block);
    case 'html':
      return { type: 'html', html: sanitizeHtmlBlock(block.html ?? '') };
    case 'heading': {
      const text = block.text.trim();
      const level = block.level === 2 || block.level === 3 ? block.level : 2;
      return { type: 'heading', level, text };
    }
    case 'list':
      return {
        type: 'list',
        ordered: Boolean(block.ordered),
        items: block.items.map((item) => item.trim()).filter(Boolean),
      };
    case 'image':
      return {
        type: 'image',
        mediaId: block.mediaId,
        ...(block.caption?.trim() ? { caption: block.caption.trim() } : {}),
      };
    case 'video':
      return {
        type: 'video',
        mediaId: block.mediaId,
        ...(block.caption?.trim() ? { caption: block.caption.trim() } : {}),
      };
    case 'gallery':
      return {
        type: 'gallery',
        items: block.items
          .filter((item) => item.mediaId?.trim())
          .map((item) => ({
            mediaId: item.mediaId.trim(),
            ...(item.caption?.trim() ? { caption: item.caption.trim() } : {}),
          })),
      };
    default:
      return block;
  }
}

function galleryReadyForSave(block: Extract<NewsBodyBlock, { type: 'gallery' }>): boolean {
  const filled = block.items.filter((item) => item.mediaId?.trim()).length;
  return filled >= MIN_GALLERY_ITEMS;
}

export function normalizeBodyBlocksForSave(blocks: NewsBodyBlock[]): NewsBodyBlock[] {
  return stripEmptyBlocks(blocks.map(normalizeBodyBlockForSave)).filter((block) => {
    if (block.type === 'gallery') return galleryReadyForSave(block);
    return true;
  });
}

export function stripEmptyBlocksFromTranslations(
  translations: NewsPostFormValues['translations'],
): NewsPostFormValues['translations'] {
  const out = { ...translations };
  for (const locale of NEWS_LOCALES) {
    out[locale] = {
      ...out[locale],
      body: normalizeBodyBlocksForSave(out[locale].body) as NewsBodyBlock[],
    };
  }
  return out;
}

export function prepareNewsSavePayload(values: NewsPostFormValues): NewsPostFormValues {
  return {
    slug: values.slug.trim(),
    category: values.category,
    scheduledAt: values.scheduledAt,
    featured: values.featured,
    translations: stripEmptyBlocksFromTranslations(values.translations),
  };
}

export function newsFormSaveFingerprint(values: NewsPostFormValues): string {
  return JSON.stringify(prepareNewsSavePayload(values));
}

/** Raw editor state for dirty detection (includes in-progress blocks not yet persisted). */
export function newsFormEditorFingerprint(values: NewsPostFormValues): string {
  return JSON.stringify({
    slug: values.slug.trim(),
    category: values.category,
    scheduledAt: values.scheduledAt,
    featured: values.featured,
    translations: values.translations,
  });
}
