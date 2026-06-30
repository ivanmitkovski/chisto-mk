import { createBlockId, type NewsBodyBlock } from '@chisto/news-content';

/** Stable across SSR and client hydration — API does not persist block ids. */
function createStableBlockId(index: number): string {
  return `block-${index}`;
}

export function createParagraphBlock(text = ''): NewsBodyBlock {
  return { id: createBlockId(), type: 'paragraph', text };
}

export function createHtmlBlock(html = ''): NewsBodyBlock {
  return { id: createBlockId(), type: 'html', html };
}

export function createHeadingBlock(level: 2 | 3 = 2, text = ''): NewsBodyBlock {
  return { id: createBlockId(), type: 'heading', level, text };
}

export function createListBlock(ordered = false, items: string[] = ['']): NewsBodyBlock {
  return { id: createBlockId(), type: 'list', ordered, items };
}

export function createImageBlock(): NewsBodyBlock {
  return { id: createBlockId(), type: 'image', mediaId: '' };
}

export function createVideoBlock(): NewsBodyBlock {
  return { id: createBlockId(), type: 'video', mediaId: '' };
}

export function createGalleryBlock(): NewsBodyBlock {
  return { id: createBlockId(), type: 'gallery', items: [{ mediaId: '' }, { mediaId: '' }] };
}

export function ensureBlocksHaveIds(blocks: NewsBodyBlock[]): NewsBodyBlock[] {
  return blocks.map((block, index) => (block.id ? block : { ...block, id: createStableBlockId(index) }));
}

export function insertBlockAt(blocks: NewsBodyBlock[], index: number, block: NewsBodyBlock): NewsBodyBlock[] {
  const next = [...blocks];
  next.splice(index, 0, block);
  return next;
}
