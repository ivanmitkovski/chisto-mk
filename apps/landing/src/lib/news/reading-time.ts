import { wordCountFromBlocks, type NewsBodyBlock } from '@chisto/news-content';

/** Typical silent reading speed for news copy (English baseline). */
const WORDS_PER_MINUTE = 200;

/**
 * Estimated reading time from article body blocks. At least 1 minute.
 */
export function estimateReadMinutesFromParagraphBlocks(blocks: readonly NewsBodyBlock[]): number {
  const words = wordCountFromBlocks([...blocks]);
  return Math.max(1, Math.ceil(words / WORDS_PER_MINUTE));
}
