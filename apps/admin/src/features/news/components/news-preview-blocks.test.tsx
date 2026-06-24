import { describe, expect, it } from 'vitest';
import { render, screen } from '@testing-library/react';
import { NewsPreviewBlocks, resolvePreviewBlocks } from './news-preview-blocks';

describe('news-preview-blocks', () => {
  it('resolves media urls into preview blocks', () => {
    const blocks = resolvePreviewBlocks(
      [
        { type: 'paragraph', text: 'Hello' },
        { type: 'image', mediaId: 'm1' },
      ],
      [{ id: 'm1', kind: 'inline_image', url: 'https://example.com/a.jpg', mimeType: 'image/jpeg', fileName: null, width: null, height: null, durationSeconds: null, altText: { en: 'Alt' }, sortOrder: 0 }],
      'en',
    );
    expect(blocks[1]).toMatchObject({ type: 'image', url: 'https://example.com/a.jpg', altText: 'Alt' });
  });

  it('renders paragraph text', () => {
    render(
      <NewsPreviewBlocks
        body={[{ type: 'paragraph', text: 'Preview paragraph' }]}
      />,
    );
    expect(screen.getByText('Preview paragraph')).toBeTruthy();
  });
});
