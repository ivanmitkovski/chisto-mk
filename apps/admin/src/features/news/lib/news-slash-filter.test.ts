import { describe, expect, it } from 'vitest';
import { fuzzyMatchSubsequence, fuzzyScore } from './news-slash-filter';

describe('news-slash-filter', () => {
  it('matches subsequence queries', () => {
    expect(fuzzyMatchSubsequence('hd', 'Heading')).toBe(true);
    expect(fuzzyMatchSubsequence('xyz', 'Heading')).toBe(false);
  });

  it('ranks closer matches higher', () => {
    expect(fuzzyScore('head', 'Heading')).toBeGreaterThan(fuzzyScore('hd', 'Gallery'));
  });
});
