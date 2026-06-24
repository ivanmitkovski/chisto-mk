import type { NewsBodyBlock } from './fetch-news';

/** Typical silent reading speed for news copy (English baseline). */
const WORDS_PER_MINUTE = 200;

function countWordsInText(text: string): number {
  const trimmed = text.trim();
  if (trimmed.length === 0) return 0;
  return trimmed.split(/\s+/).filter(Boolean).length;
}

/**
 * Estimated reading time from paragraph blocks in the article body. At least 1 minute.
 */
export function estimateReadMinutesFromParagraphBlocks(blocks: readonly NewsBodyBlock[]): number {
  let words = 0;
  for (const block of blocks) {
    if (block.type === 'paragraph') {
      words += countWordsInText(block.text);
    }
  }
  return Math.max(1, Math.ceil(words / WORDS_PER_MINUTE));
}
