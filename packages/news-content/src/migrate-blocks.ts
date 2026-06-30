import type { NewsBodyBlock } from './types';
import { createBlockId, galleryHasContent, isParagraphBlock } from './types';
import {
  hasVisibleText,
  htmlBlockHasContent,
  sanitizeHtmlBlock,
  sanitizeInlineHtml,
  stripHtmlToPlainText,
} from './sanitize/html-sanitize';

export function ensureBlockIds(blocks: NewsBodyBlock[]): NewsBodyBlock[] {
  return blocks.map((block) => (block.id ? block : { ...block, id: createBlockId() }));
}

export function sanitizeParagraphBlock(block: Extract<NewsBodyBlock, { type: 'paragraph' }>): Extract<NewsBodyBlock, { type: 'paragraph' }> {
  const html = block.html?.trim() ? sanitizeInlineHtml(block.html) : undefined;
  const text = block.text?.trim()
    ? block.text.trim()
    : html
      ? stripHtmlToPlainText(html)
      : '';
  return {
    ...block,
    text,
    ...(html ? { html } : {}),
  };
}

export function sanitizeHtmlBlockEntry(block: Extract<NewsBodyBlock, { type: 'html' }>): Extract<NewsBodyBlock, { type: 'html' }> {
  return {
    ...block,
    html: sanitizeHtmlBlock(block.html ?? ''),
  };
}

export function sanitizeBodyBlocks(blocks: NewsBodyBlock[]): NewsBodyBlock[] {
  return ensureBlockIds(blocks).map((block) => {
    switch (block.type) {
      case 'paragraph':
        return sanitizeParagraphBlock(block);
      case 'html':
        return sanitizeHtmlBlockEntry(block);
      case 'heading':
        return { ...block, text: block.text.trim() };
      case 'list':
        return {
          ...block,
          items: block.items.map((item) => item.trim()).filter(Boolean),
        };
      default:
        return block;
    }
  });
}

export function stripEmptyBlocks(blocks: NewsBodyBlock[]): NewsBodyBlock[] {
  return blocks.filter((block) => {
    if (isParagraphBlock(block)) {
      const html = block.html?.trim();
      const text = block.text?.trim();
      return Boolean(text) || (html ? hasVisibleText(html) : false);
    }
    if (block.type === 'html') {
      return htmlBlockHasContent(block.html);
    }
    if (block.type === 'heading') {
      return Boolean(block.text.trim());
    }
    if (block.type === 'list') {
      return block.items.some((item) => item.trim());
    }
    if (block.type === 'image' || block.type === 'video') {
      return Boolean(block.mediaId?.trim());
    }
    if (block.type === 'gallery') {
      return galleryHasContent(block);
    }
    return true;
  });
}

export function migrateLegacyBlocks(blocks: NewsBodyBlock[]): NewsBodyBlock[] {
  return ensureBlockIds(blocks);
}
