import { createBlockId, type NewsBodyBlock } from '@chisto/news-content';

/** Stable ids assigned on load; persisted in translations.body JSON (ADR-1). */
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

export function createQuoteBlock(text = ''): NewsBodyBlock {
  return { id: createBlockId(), type: 'quote', text };
}

export function createDividerBlock(): NewsBodyBlock {
  return { id: createBlockId(), type: 'divider' };
}

export function createEmbedBlock(url = '', provider: 'youtube' | 'vimeo' = 'youtube'): NewsBodyBlock {
  return { id: createBlockId(), type: 'embed', provider, url };
}

export function ensureBlocksHaveIds(blocks: NewsBodyBlock[]): NewsBodyBlock[] {
  return blocks.map((block, index) => (block.id ? block : { ...block, id: createStableBlockId(index) }));
}

export function insertBlockAt(blocks: NewsBodyBlock[], index: number, block: NewsBodyBlock): NewsBodyBlock[] {
  const next = [...blocks];
  next.splice(index, 0, block);
  return next;
}
