export type NewsBodyBlockBase = { id?: string };

export type NewsParagraphBlock = NewsBodyBlockBase & {
  type: 'paragraph';
  text: string;
  html?: string;
};

export type NewsHtmlBlock = NewsBodyBlockBase & {
  type: 'html';
  html: string;
};

export type NewsHeadingBlock = NewsBodyBlockBase & {
  type: 'heading';
  level: 2 | 3;
  text: string;
};

export type NewsListBlock = NewsBodyBlockBase & {
  type: 'list';
  ordered: boolean;
  items: string[];
};

export type NewsImageBlock = NewsBodyBlockBase & {
  type: 'image';
  mediaId: string;
  caption?: string;
};

export type NewsVideoBlock = NewsBodyBlockBase & {
  type: 'video';
  mediaId: string;
  caption?: string;
};

export type NewsGalleryItem = {
  mediaId: string;
  caption?: string;
};

export type NewsGalleryBlock = NewsBodyBlockBase & {
  type: 'gallery';
  items: NewsGalleryItem[];
};

export type NewsBodyBlock =
  | NewsParagraphBlock
  | NewsHtmlBlock
  | NewsHeadingBlock
  | NewsListBlock
  | NewsImageBlock
  | NewsVideoBlock
  | NewsGalleryBlock;

export type EnrichedMediaBlock = (NewsImageBlock | NewsVideoBlock) & {
  url?: string | null;
  altText?: string | null;
};

export type EnrichedGalleryItem = NewsGalleryItem & {
  url?: string | null;
  altText?: string | null;
};

export type EnrichedGalleryBlock = NewsGalleryBlock & {
  items: EnrichedGalleryItem[];
};

export type ResolvedNewsBodyBlock =
  | NewsParagraphBlock
  | NewsHtmlBlock
  | NewsHeadingBlock
  | NewsListBlock
  | EnrichedMediaBlock
  | EnrichedGalleryBlock;

export function createBlockId(): string {
  if (typeof crypto !== 'undefined' && typeof crypto.randomUUID === 'function') {
    return crypto.randomUUID();
  }
  return `block-${Date.now()}-${Math.random().toString(36).slice(2, 11)}`;
}

export function isParagraphBlock(block: NewsBodyBlock): block is NewsParagraphBlock {
  return block.type === 'paragraph';
}

export function isHtmlBlock(block: NewsBodyBlock): block is NewsHtmlBlock {
  return block.type === 'html';
}

export function isHeadingBlock(block: NewsBodyBlock): block is NewsHeadingBlock {
  return block.type === 'heading';
}

export function isListBlock(block: NewsBodyBlock): block is NewsListBlock {
  return block.type === 'list';
}

export function isMediaBlock(block: NewsBodyBlock): block is NewsImageBlock | NewsVideoBlock {
  return block.type === 'image' || block.type === 'video';
}

export function isGalleryBlock(block: NewsBodyBlock): block is NewsGalleryBlock {
  return block.type === 'gallery';
}

export function galleryHasContent(block: NewsGalleryBlock): boolean {
  return block.items.some((item) => Boolean(item.mediaId?.trim()));
}

export function mediaIdsFromBlocks(blocks: NewsBodyBlock[]): string[] {
  const ids: string[] = [];
  for (const block of blocks) {
    if (block.type === 'image' || block.type === 'video') {
      if (block.mediaId?.trim()) ids.push(block.mediaId);
    }
    if (block.type === 'gallery') {
      for (const item of block.items) {
        if (item.mediaId?.trim()) ids.push(item.mediaId);
      }
    }
  }
  return ids;
}
