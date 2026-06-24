import { describe, expect, it } from 'vitest';
import { estimateReadMinutesFromParagraphBlocks } from './reading-time';

describe('reading-time', () => {
  it('estimates minutes from paragraph word count', () => {
    const words = Array.from({ length: 400 }, () => 'word').join(' ');
    expect(estimateReadMinutesFromParagraphBlocks([{ type: 'paragraph', text: words }])).toBe(2);
  });

  it('returns at least 1 minute', () => {
    expect(estimateReadMinutesFromParagraphBlocks([{ type: 'paragraph', text: 'Hi' }])).toBe(1);
  });
});
