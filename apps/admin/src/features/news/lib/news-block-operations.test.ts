import { describe, expect, it } from 'vitest';
import type { NewsBodyBlock } from '../news-api-types';
import {
  duplicateBlockAt,
  isTransformableBlock,
  mergeParagraphWithPrevious,
  removeBlockAt,
  replaceBlockAt,
  replaceBlockWithMany,
  restoreBlockAt,
  splitHtmlIntoParagraphBlocks,
  transformBlockAt,
} from './news-block-operations';

const paragraph: NewsBodyBlock = { id: 'p1', type: 'paragraph', text: 'Hello world' };
const richParagraph: NewsBodyBlock = {
  id: 'p2',
  type: 'paragraph',
  text: 'Hello world',
  html: '<p>Hello <strong>world</strong></p>',
};
const heading: NewsBodyBlock = { id: 'h1', type: 'heading', level: 2, text: 'Title' };
const list: NewsBodyBlock = { id: 'l1', type: 'list', ordered: true, items: ['One', 'Two'] };
const image: NewsBodyBlock = { id: 'i1', type: 'image', mediaId: 'm1' };

describe('transformBlockAt', () => {
  it('converts paragraph to heading keeping the first line of text', () => {
    const out = transformBlockAt([paragraph], 0, 'heading2');
    expect(out[0]).toMatchObject({ type: 'heading', level: 2, text: 'Hello world', id: 'p1' });
  });

  it('drops inline formatting when transforming a rich paragraph', () => {
    const out = transformBlockAt([richParagraph], 0, 'heading3');
    expect(out[0]).toMatchObject({ type: 'heading', level: 3, text: 'Hello world' });
    expect('html' in out[0]!).toBe(false);
  });

  it('converts list to paragraph joining items with newlines', () => {
    const out = transformBlockAt([list], 0, 'paragraph');
    expect(out[0]).toMatchObject({ type: 'paragraph', text: 'One\nTwo' });
  });

  it('converts paragraph with newlines to list items', () => {
    const source: NewsBodyBlock = { id: 'p3', type: 'paragraph', text: 'One\nTwo\n\nThree' };
    const out = transformBlockAt([source], 0, 'list');
    expect(out[0]).toMatchObject({ type: 'list', ordered: false, items: ['One', 'Two', 'Three'] });
  });

  it('keeps list ordering when converting heading level', () => {
    const out = transformBlockAt([heading], 0, 'list');
    expect(out[0]).toMatchObject({ type: 'list', items: ['Title'] });
  });

  it('does not transform media blocks', () => {
    const blocks = [image];
    expect(transformBlockAt(blocks, 0, 'paragraph')).toBe(blocks);
    expect(isTransformableBlock(image)).toBe(false);
  });
});

describe('duplicateBlockAt', () => {
  it('inserts a copy with a fresh id right after the source', () => {
    const out = duplicateBlockAt([paragraph, heading], 0);
    expect(out).toHaveLength(3);
    expect(out[1]).toMatchObject({ type: 'paragraph', text: 'Hello world' });
    expect(out[1]!.id).not.toBe(paragraph.id);
    expect(out[2]).toBe(heading);
  });

  it('deep-copies gallery items', () => {
    const gallery: NewsBodyBlock = {
      id: 'g1',
      type: 'gallery',
      items: [{ mediaId: 'm1', caption: 'a' }, { mediaId: 'm2' }],
    };
    const out = duplicateBlockAt([gallery], 0);
    const copy = out[1] as Extract<NewsBodyBlock, { type: 'gallery' }>;
    expect(copy.items).toEqual(gallery.items);
    expect(copy.items[0]).not.toBe(gallery.items[0]);
  });
});

describe('remove/restore/replace', () => {
  it('removes and restores a block at the same index', () => {
    const blocks = [paragraph, heading, list];
    const removed = removeBlockAt(blocks, 1);
    expect(removed.map((b) => b.id)).toEqual(['p1', 'l1']);
    const restored = restoreBlockAt(removed, 1, heading);
    expect(restored.map((b) => b.id)).toEqual(['p1', 'h1', 'l1']);
  });

  it('clamps restore index to bounds', () => {
    const restored = restoreBlockAt([paragraph], 99, heading);
    expect(restored.map((b) => b.id)).toEqual(['p1', 'h1']);
  });

  it('replaces a block in place', () => {
    const out = replaceBlockAt([paragraph, heading], 0, list);
    expect(out.map((b) => b.id)).toEqual(['l1', 'h1']);
  });

  it('ignores out-of-range replace', () => {
    const blocks = [paragraph];
    expect(replaceBlockAt(blocks, 5, list)).toBe(blocks);
  });
});

describe('mergeParagraphWithPrevious', () => {
  const prev: NewsBodyBlock = {
    id: 'p1',
    type: 'paragraph',
    text: 'Hello',
    html: '<p>Hello</p>',
  };
  const current: NewsBodyBlock = {
    id: 'p2',
    type: 'paragraph',
    text: 'World',
    html: '<p>World</p>',
  };

  it('merges two paragraphs and keeps the previous id', () => {
    const out = mergeParagraphWithPrevious([prev, current], 1);
    expect(out).toHaveLength(1);
    expect(out[0]).toMatchObject({ id: 'p1', type: 'paragraph', text: 'HelloWorld' });
  });
});

describe('splitHtmlIntoParagraphBlocks', () => {
  it('splits multiple paragraphs into separate blocks', () => {
    const out = splitHtmlIntoParagraphBlocks('<p>One</p><p>Two</p>');
    expect(out).toHaveLength(2);
    expect(out[0]).toMatchObject({ type: 'paragraph', text: 'One' });
    expect(out[1]).toMatchObject({ type: 'paragraph', text: 'Two' });
  });
});

describe('replaceBlockWithMany', () => {
  it('replaces one block with several', () => {
    const replacements: NewsBodyBlock[] = [
      { id: 'a', type: 'paragraph', text: 'A' },
      { id: 'b', type: 'paragraph', text: 'B' },
    ];
    const out = replaceBlockWithMany([paragraph, heading], 0, replacements);
    expect(out.map((b) => b.id)).toEqual(['a', 'b', 'h1']);
  });
});
