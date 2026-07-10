import type { ResolvedNewsBodyBlock } from '../types';

export type NewsHeadingTocItem = {
  id: string;
  title: string;
  level: 2 | 3;
};

export type NewsHeadingAnchor = NewsHeadingTocItem & {
  blockIndex: number;
};

/** Stable URL-safe slug for in-article heading anchors (Unicode letters/digits). */
export function slugifyNewsHeading(text: string): string {
  const slug = text
    .normalize('NFKD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .trim()
    .replace(/[^\p{L}\p{N}]+/gu, '-')
    .replace(/^-+|-+$/g, '');
  return slug || 'section';
}

function uniqueHeadingId(base: string, used: Map<string, number>): string {
  const count = used.get(base) ?? 0;
  used.set(base, count + 1);
  return count === 0 ? base : `${base}-${count + 1}`;
}

/** Walk body blocks and assign deduped heading ids in document order. */
export function collectHeadingAnchors(
  blocks: readonly ResolvedNewsBodyBlock[],
): NewsHeadingAnchor[] {
  const used = new Map<string, number>();
  const anchors: NewsHeadingAnchor[] = [];

  blocks.forEach((block, blockIndex) => {
    if (block.type !== 'heading') return;
    const title = block.text.trim();
    if (!title) return;
    const id = uniqueHeadingId(slugifyNewsHeading(title), used);
    anchors.push({
      blockIndex,
      id,
      title,
      level: block.level,
    });
  });

  return anchors;
}

/**
 * TOC entries for news articles. Defaults to h2 only — show when length ≥ 3.
 */
export function extractNewsHeadingToc(
  blocks: readonly ResolvedNewsBodyBlock[],
  options?: { levels?: readonly (2 | 3)[] },
): NewsHeadingTocItem[] {
  const levels = options?.levels ?? ([2] as const);
  return collectHeadingAnchors(blocks)
    .filter((anchor) => levels.includes(anchor.level))
    .map(({ id, title, level }) => ({ id, title, level }));
}
