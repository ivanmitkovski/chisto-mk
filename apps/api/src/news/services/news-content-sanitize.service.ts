import {
  ensureBlockIds,
  hasVisibleText,
  sanitizeBodyBlocks,
  stripEmptyBlocks,
  stripHtmlToPlainText,
  type NewsBodyBlock,
} from '@chisto/news-content';

export { ensureBlockIds, sanitizeBodyBlocks };

export function normalizeTranslationsBody(translations: {
  en: { title: string; excerpt: string; body: NewsBodyBlock[] };
  mk: { title: string; excerpt: string; body: NewsBodyBlock[] };
  sq: { title: string; excerpt: string; body: NewsBodyBlock[] };
}) {
  return {
    en: { ...translations.en, body: stripEmptyBlocks(sanitizeBodyBlocks(translations.en.body ?? [])) },
    mk: { ...translations.mk, body: stripEmptyBlocks(sanitizeBodyBlocks(translations.mk.body ?? [])) },
    sq: { ...translations.sq, body: stripEmptyBlocks(sanitizeBodyBlocks(translations.sq.body ?? [])) },
  };
}

export function paragraphHasContent(block: Extract<NewsBodyBlock, { type: 'paragraph' }>): boolean {
  const text = block.text?.trim() ?? '';
  if (text) return true;
  const html = block.html?.trim();
  return html ? hasVisibleText(html) : false;
}

export function paragraphPlainText(block: Extract<NewsBodyBlock, { type: 'paragraph' }>): string {
  const text = block.text?.trim() ?? '';
  if (text) return text;
  const html = block.html?.trim();
  return html ? stripHtmlToPlainText(html) : '';
}
