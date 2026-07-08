import {
  MIN_GALLERY_ITEMS,
  normalizeInlineLinksInHtml,
  sanitizeHtmlBlock,
  sanitizeInlineHtml,
  stripEmptyBlocks,
  stripHtmlToPlainText,
  type NewsBodyBlock,
} from '@chisto/news-content';
import type { NewsPostFormValues } from '../types';
import { NEWS_LOCALES } from '../types';

/**
 * Block ids are persisted in the stored translations.body JSON (the API's
 * sanitizeBodyBlocks preserves ids it receives), keeping React keys and
 * editor focus stable across save → reload. See ADR-1 in the upgrade plan.
 */
function withBlockId<T extends NewsBodyBlock>(source: NewsBodyBlock, block: T): T {
  return source.id ? { ...block, id: source.id } : block;
}

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

  const sanitized = normalizeInlineLinksInHtml(sanitizeInlineHtml(html));
  const htmlPlain = stripHtmlToPlainText(sanitized).trim();

  if (!sanitized || !htmlPlain) {
    return { type: 'paragraph', text };
  }

  if (paragraphHtmlIsRedundant(text, sanitized)) {
    return { type: 'paragraph', text: htmlPlain };
  }

  return { type: 'paragraph', text: text || htmlPlain, html: sanitized };
}

/** Normalizes body blocks for API + dirty comparison, keeping stable block ids. */
export function normalizeBodyBlockForSave(block: NewsBodyBlock): NewsBodyBlock {
  switch (block.type) {
    case 'paragraph':
      return withBlockId(block, normalizeParagraphBlock(block));
    case 'html':
      return withBlockId(block, { type: 'html', html: sanitizeHtmlBlock(block.html ?? '') });
    case 'heading': {
      const text = block.text.trim();
      const level = block.level === 2 || block.level === 3 ? block.level : 2;
      return withBlockId(block, { type: 'heading', level, text });
    }
    case 'list':
      return withBlockId(block, {
        type: 'list',
        ordered: Boolean(block.ordered),
        items: block.items.map((item) => item.trim()).filter(Boolean),
      });
    case 'image':
      return withBlockId(block, {
        type: 'image',
        mediaId: block.mediaId,
        ...(block.caption?.trim() ? { caption: block.caption.trim() } : {}),
      });
    case 'video':
      return withBlockId(block, {
        type: 'video',
        mediaId: block.mediaId,
        ...(block.caption?.trim() ? { caption: block.caption.trim() } : {}),
      });
    case 'gallery':
      return withBlockId(block, {
        type: 'gallery',
        items: block.items
          .filter((item) => item.mediaId?.trim())
          .map((item) => ({
            mediaId: item.mediaId.trim(),
            ...(item.caption?.trim() ? { caption: item.caption.trim() } : {}),
          })),
      });
    case 'quote': {
      const text = block.text.trim();
      const attribution = block.attribution?.trim();
      return withBlockId(block, {
        type: 'quote',
        text,
        ...(attribution ? { attribution } : {}),
      });
    }
    case 'divider':
      return withBlockId(block, { type: 'divider' });
    case 'embed':
      return withBlockId(block, {
        type: 'embed',
        provider: block.provider,
        url: block.url.trim(),
      });
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
