import {
  createBlockId,
  sanitizeInlineHtml,
  splitHtmlIntoParagraphBlocks as splitHtmlIntoParagraphBlocksShared,
  paragraphBlocksFromPlainText as paragraphBlocksFromPlainTextShared,
  stripHtmlToPlainText,
  type NewsBodyBlock,
} from '@chisto/news-content';

type ParagraphBlock = Extract<NewsBodyBlock, { type: 'paragraph' }>;

export type TransformTarget = 'paragraph' | 'heading2' | 'heading3' | 'list' | 'quote';

type TextishBlock = Extract<NewsBodyBlock, { type: 'paragraph' | 'heading' | 'list' | 'quote' }>;

export function isTransformableBlock(block: NewsBodyBlock): block is TextishBlock {
  return (
    block.type === 'paragraph' ||
    block.type === 'heading' ||
    block.type === 'list' ||
    block.type === 'quote'
  );
}

/** Plain text carried across a transform (formatting is dropped intentionally). */
function blockPlainText(block: TextishBlock): string {
  if (block.type === 'paragraph') {
    return block.html ? stripHtmlToPlainText(block.html) : block.text.trim();
  }
  if (block.type === 'heading') return block.text.trim();
  if (block.type === 'quote') return block.text.trim();
  return block.items
    .map((item) => item.trim())
    .filter(Boolean)
    .join('\n');
}

export function transformBlock(block: NewsBodyBlock, target: TransformTarget): NewsBodyBlock {
  if (!isTransformableBlock(block)) return block;
  const id = block.id ?? createBlockId();
  const text = blockPlainText(block);

  switch (target) {
    case 'paragraph':
      return { id, type: 'paragraph', text };
    case 'heading2':
      return { id, type: 'heading', level: 2, text: text.split('\n')[0] ?? '' };
    case 'heading3':
      return { id, type: 'heading', level: 3, text: text.split('\n')[0] ?? '' };
    case 'list': {
      const items = text.split('\n').map((item) => item.trim()).filter(Boolean);
      const ordered = block.type === 'list' ? block.ordered : false;
      return { id, type: 'list', ordered, items: items.length ? items : [''] };
    }
    case 'quote':
      return { id, type: 'quote', text: text.split('\n')[0] ?? '' };
  }
}

export function transformBlockAt(
  blocks: NewsBodyBlock[],
  index: number,
  target: TransformTarget,
): NewsBodyBlock[] {
  const block = blocks[index];
  if (!block || !isTransformableBlock(block)) return blocks;
  const next = [...blocks];
  next[index] = transformBlock(block, target);
  return next;
}

/** Deep-copies a block with fresh ids so React keys and dnd stay stable. */
export function duplicateBlock(block: NewsBodyBlock): NewsBodyBlock {
  const copy: NewsBodyBlock = { ...block, id: createBlockId() };
  if (copy.type === 'list') copy.items = [...copy.items];
  if (copy.type === 'gallery') copy.items = copy.items.map((item) => ({ ...item }));
  return copy;
}

export function duplicateBlockAt(blocks: NewsBodyBlock[], index: number): NewsBodyBlock[] {
  const block = blocks[index];
  if (!block) return blocks;
  const next = [...blocks];
  next.splice(index + 1, 0, duplicateBlock(block));
  return next;
}

export function removeBlockAt(blocks: NewsBodyBlock[], index: number): NewsBodyBlock[] {
  return blocks.filter((_, i) => i !== index);
}

export function restoreBlockAt(
  blocks: NewsBodyBlock[],
  index: number,
  block: NewsBodyBlock,
): NewsBodyBlock[] {
  const next = [...blocks];
  next.splice(Math.min(Math.max(index, 0), next.length), 0, block);
  return next;
}

/** Replaces an (empty) block in place — used by the slash command palette. */
export function replaceBlockAt(
  blocks: NewsBodyBlock[],
  index: number,
  block: NewsBodyBlock,
): NewsBodyBlock[] {
  if (index < 0 || index >= blocks.length) return blocks;
  const next = [...blocks];
  next[index] = block;
  return next;
}

export function splitHtmlIntoParagraphBlocks(html: string): NewsBodyBlock[] {
  return splitHtmlIntoParagraphBlocksShared(html);
}

export function paragraphBlocksFromPlainText(text: string): NewsBodyBlock[] {
  return paragraphBlocksFromPlainTextShared(text);
}

/**
 * Merges the source paragraph into the target (Backspace at start of block).
 * The result keeps target's id so the mounted editor updates in place.
 */
export function mergeParagraphBlocks(
  target: ParagraphBlock,
  source: ParagraphBlock,
): ParagraphBlock {
  const targetHtml = target.html?.trim() || (target.text.trim() ? `<p>${target.text}</p>` : '');
  const sourceHtml = source.html?.trim() || (source.text.trim() ? `<p>${source.text}</p>` : '');
  const combined = sanitizeInlineHtml(`${targetHtml}${sourceHtml}`);
  const text = stripHtmlToPlainText(combined);
  const merged: ParagraphBlock = { type: 'paragraph', text };
  if (target.id) merged.id = target.id;
  if (combined && combined !== `<p>${text}</p>`) merged.html = combined;
  return merged;
}

/** Merges blocks[index] into blocks[index - 1] when both are paragraphs. */
export function mergeParagraphWithPrevious(
  blocks: NewsBodyBlock[],
  index: number,
): NewsBodyBlock[] {
  const prev = blocks[index - 1];
  const current = blocks[index];
  if (!prev || !current || prev.type !== 'paragraph' || current.type !== 'paragraph') {
    return blocks;
  }
  const next = [...blocks];
  next[index - 1] = mergeParagraphBlocks(prev, current);
  next.splice(index, 1);
  return next;
}

/** Replaces blocks[index] with the given blocks (multi-paragraph paste). */
export function replaceBlockWithMany(
  blocks: NewsBodyBlock[],
  index: number,
  replacements: NewsBodyBlock[],
): NewsBodyBlock[] {
  if (index < 0 || index >= blocks.length || replacements.length === 0) return blocks;
  const next = [...blocks];
  next.splice(index, 1, ...replacements);
  return next;
}

/** Inserts imported blocks at index, removing the block at index when it is empty. */
export function insertImportedBlocksAt(
  blocks: NewsBodyBlock[],
  index: number,
  replacements: NewsBodyBlock[],
): NewsBodyBlock[] {
  if (replacements.length === 0) return blocks;
  const current = blocks[index];
  const removeCurrent =
    current &&
    current.type === 'paragraph' &&
    !current.text?.trim() &&
    !current.html?.trim();
  const next = [...blocks];
  if (removeCurrent) {
    next.splice(index, 1, ...replacements);
  } else {
    next.splice(index + 1, 0, ...replacements);
  }
  return next;
}
