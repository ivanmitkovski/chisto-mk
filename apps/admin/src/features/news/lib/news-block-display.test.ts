import { describe, expect, it } from 'vitest';
import type { NewsBodyBlock } from '../news-api-types';
import { blockPreviewText, blockTypeLabel } from './news-block-display';

const t = (key: string) => key;

describe('news-block-display', () => {
  it('labels paragraph blocks', () => {
    const block: NewsBodyBlock = { id: 'a', type: 'paragraph', text: 'Hello' };
    expect(blockTypeLabel(block, t)).toBe('form.blockParagraph');
  });

  it('previews paragraph text without html tags', () => {
    const block: NewsBodyBlock = {
      id: 'a',
      type: 'paragraph',
      text: '',
      html: '<p>Hello <strong>world</strong></p>',
    };
    expect(blockPreviewText(block)).toBe('Hello world');
  });

  it('previews heading text', () => {
    const block: NewsBodyBlock = { id: 'a', type: 'heading', level: 2, text: 'Title' };
    expect(blockPreviewText(block)).toBe('Title');
  });
});
