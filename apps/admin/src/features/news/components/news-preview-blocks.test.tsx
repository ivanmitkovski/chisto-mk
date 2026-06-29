import { describe, expect, it } from 'vitest';
import { render, screen } from '@testing-library/react';
import { NextIntlClientProvider } from 'next-intl';
import { NewsPreviewBlocks, resolvePreviewBlocks } from './news-preview-blocks';

const messages = {
  news: {
    previewBlocks: {
      imageUnavailable: 'Image unavailable',
      videoUnavailable: 'Video unavailable',
      unknownBlock: 'Unsupported block',
    },
  },
};

function renderBlocks(body: Parameters<typeof NewsPreviewBlocks>[0]['body']) {
  return render(
    <NextIntlClientProvider locale="en" messages={messages}>
      <NewsPreviewBlocks body={body} />
    </NextIntlClientProvider>,
  );
}

describe('news-preview-blocks', () => {
  it('resolves media urls into preview blocks', () => {
    const blocks = resolvePreviewBlocks(
      [
        { type: 'paragraph', text: 'Hello' },
        { type: 'image', mediaId: 'm1' },
      ],
      [
        {
          id: 'm1',
          kind: 'inline_image',
          url: 'https://example.com/a.jpg',
          mimeType: 'image/jpeg',
          fileName: null,
          altText: { en: 'Alt' },
        },
      ],
      'en',
    );
    expect(blocks[1]).toMatchObject({ type: 'image', url: 'https://example.com/a.jpg', altText: 'Alt' });
  });

  it('renders paragraph text', () => {
    renderBlocks([{ type: 'paragraph', text: 'Preview paragraph' }]);
    expect(screen.getByText('Preview paragraph')).toBeTruthy();
  });

  it('renders rich paragraph links', () => {
    renderBlocks([
      {
        type: 'paragraph',
        text: 'Click here',
        html: '<p>Click <a href="https://example.com">here</a></p>',
      },
    ]);
    const link = screen.getByRole('link', { name: 'here' });
    expect(link.getAttribute('href')).toBe('https://example.com');
  });
});
