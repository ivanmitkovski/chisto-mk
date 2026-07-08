import { sanitizeInlineHtml, stripHtmlToPlainText } from '../sanitize/html-sanitize';
import { createBlockId, type NewsBodyBlock, type NewsParagraphBlock } from '../types';

export function paragraphFromHtml(html: string, id?: string): NewsParagraphBlock {
  const safe = sanitizeInlineHtml(html);
  const text = stripHtmlToPlainText(safe);
  const block: NewsParagraphBlock = {
    id: id ?? createBlockId(),
    type: 'paragraph',
    text,
  };
  const inner = safe.replace(/^<p>/i, '').replace(/<\/p>$/i, '');
  if (safe && (inner.includes('<') || !/^<p>[\s\S]*<\/p>$/i.test(safe))) {
    block.html = safe;
  }
  return block;
}

/**
 * Splits sanitized inline HTML into one paragraph block per top-level
 * <p>/<ul>/<ol> segment.
 */
export function splitHtmlIntoParagraphBlocks(html: string): NewsBodyBlock[] {
  const safe = sanitizeInlineHtml(html);
  if (!safe) return [];
  const segments = safe.match(/<p>[\s\S]*?<\/p>|<ul>[\s\S]*?<\/ul>|<ol>[\s\S]*?<\/ol>/gi);
  if (!segments || segments.length === 0) {
    const block = paragraphFromHtml(safe);
    return block.text || block.html ? [block] : [];
  }
  return segments
    .map((segment) => paragraphFromHtml(segment))
    .filter((block) => block.text.trim() || block.html);
}

/** Splits pasted plain text into paragraph blocks on blank lines. */
export function paragraphBlocksFromPlainText(text: string): NewsBodyBlock[] {
  return text
    .split(/\r?\n\s*\r?\n|\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean)
    .map((line) => ({ id: createBlockId(), type: 'paragraph' as const, text: line }));
}
