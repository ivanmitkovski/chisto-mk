import { describe, expect, it } from 'vitest';
import { copyBodyBlocksFromSource } from './copy-locale-content';

describe('copyBodyBlocksFromSource', () => {
  it('copies paragraph text and preserves media ids', () => {
    const result = copyBodyBlocksFromSource([
      { type: 'paragraph', text: 'Hello', html: '<p>Hello</p>' },
      { type: 'image', mediaId: 'img1', caption: 'Cap' },
      { type: 'video', mediaId: 'vid1' },
      { type: 'heading', level: 2, text: 'Title' },
      { type: 'list', ordered: true, items: ['A', 'B'] },
      { type: 'html', html: '<p>Block</p>' },
    ]);
    expect(result).toHaveLength(6);
    expect(result[0]).toMatchObject({ type: 'paragraph', text: 'Hello', html: '<p>Hello</p>' });
    expect(result[0].id).toBeTruthy();
    expect(result[1]).toMatchObject({ type: 'image', mediaId: 'img1', caption: 'Cap' });
    expect(result[3]).toMatchObject({ type: 'heading', level: 2, text: 'Title' });
    expect(result[4]).toMatchObject({ type: 'list', ordered: true, items: ['A', 'B'] });
    expect(result[5]).toMatchObject({ type: 'html', html: '<p>Block</p>' });
  });
});
