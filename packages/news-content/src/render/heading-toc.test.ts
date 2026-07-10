import { describe, expect, it } from 'vitest';
import type { ResolvedNewsBodyBlock } from '../types';
import {
  collectHeadingAnchors,
  extractNewsHeadingToc,
  slugifyNewsHeading,
} from './heading-toc';

describe('slugifyNewsHeading', () => {
  it('slugifies latin text', () => {
    expect(slugifyNewsHeading('Hello World!')).toBe('hello-world');
  });

  it('keeps cyrillic letters', () => {
    expect(slugifyNewsHeading('Новости од Чистo')).toMatch(/новости/);
  });

  it('falls back for empty-ish input', () => {
    expect(slugifyNewsHeading('   ')).toBe('section');
    expect(slugifyNewsHeading('!!!')).toBe('section');
  });
});

describe('collectHeadingAnchors / extractNewsHeadingToc', () => {
  const blocks: ResolvedNewsBodyBlock[] = [
    { type: 'paragraph', text: 'Intro' },
    { type: 'heading', level: 2, text: 'First' },
    { type: 'heading', level: 3, text: 'Nested' },
    { type: 'heading', level: 2, text: 'Second' },
    { type: 'heading', level: 2, text: 'First' },
    { type: 'heading', level: 2, text: 'Third' },
  ];

  it('dedupes identical titles', () => {
    const anchors = collectHeadingAnchors(blocks);
    expect(anchors.map((a) => a.id)).toEqual([
      'first',
      'nested',
      'second',
      'first-2',
      'third',
    ]);
  });

  it('extracts h2 toc by default', () => {
    const toc = extractNewsHeadingToc(blocks);
    expect(toc).toEqual([
      { id: 'first', title: 'First', level: 2 },
      { id: 'second', title: 'Second', level: 2 },
      { id: 'first-2', title: 'First', level: 2 },
      { id: 'third', title: 'Third', level: 2 },
    ]);
  });
});
