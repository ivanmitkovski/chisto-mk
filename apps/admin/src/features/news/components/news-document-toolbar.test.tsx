import { describe, expect, it } from 'vitest';
import type { NewsBodyBlock } from '../news-api-types';
import { mergeBlocksAtIndex } from './news-document-toolbar';

describe('mergeBlocksAtIndex', () => {
  it('inserts blocks at the requested index', () => {
    const current: NewsBodyBlock[] = [
      { id: 'a', type: 'paragraph', text: 'One' },
      { id: 'b', type: 'paragraph', text: 'Two' },
    ];
    const inserted: NewsBodyBlock[] = [{ id: 'c', type: 'heading', level: 2, text: 'Mid' }];

    const next = mergeBlocksAtIndex(current, 1, inserted);

    expect(next.map((block) => block.id)).toEqual(['a', 'c', 'b']);
  });
});
