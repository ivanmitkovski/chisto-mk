import { describe, expect, it } from 'vitest';
import { ensureBlocksHaveIds } from './news-block-factory';

describe('ensureBlocksHaveIds', () => {
  it('assigns stable index-based ids for hydration', () => {
    const blocks = [
      { type: 'paragraph' as const, text: 'One' },
      { type: 'heading' as const, level: 2 as const, text: 'Two' },
    ];

    expect(ensureBlocksHaveIds(blocks)).toEqual([
      { type: 'paragraph', text: 'One', id: 'block-0' },
      { type: 'heading', level: 2, text: 'Two', id: 'block-1' },
    ]);
    expect(ensureBlocksHaveIds(blocks)).toEqual(ensureBlocksHaveIds(blocks));
  });

  it('preserves existing ids', () => {
    const blocks = [{ id: 'existing-id', type: 'paragraph' as const, text: 'Hello' }];
    expect(ensureBlocksHaveIds(blocks)[0]?.id).toBe('existing-id');
  });
});
