import { describe, expect, it } from 'vitest';
import { copyBodyBlocksFromSource } from './copy-locale-content';

describe('copyBodyBlocksFromSource', () => {
  it('copies paragraph text and preserves media ids', () => {
    const result = copyBodyBlocksFromSource([
      { type: 'paragraph', text: 'Hello' },
      { type: 'image', mediaId: 'img1', caption: 'Cap' },
      { type: 'video', mediaId: 'vid1' },
    ]);
    expect(result).toEqual([
      { type: 'paragraph', text: 'Hello' },
      { type: 'image', mediaId: 'img1', caption: 'Cap' },
      { type: 'video', mediaId: 'vid1' },
    ]);
  });
});
