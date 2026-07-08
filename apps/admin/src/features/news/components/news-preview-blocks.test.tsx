import { describe, expect, it } from 'vitest';
import { fireEvent, render, screen } from '@testing-library/react';
import { NextIntlClientProvider } from 'next-intl';
import { NewsPreviewBlocks, resolvePreviewBlocks } from './news-preview-blocks';

const messages = {
  news: {
    previewBlocks: {
      imageUnavailable: 'Image unavailable',
      videoUnavailable: 'Video unavailable',
      unknownBlock: 'Unsupported block',
      galleryUnavailable: 'Gallery unavailable',
      galleryClose: 'Close',
      galleryPrevious: 'Previous image',
      galleryNext: 'Next image',
      galleryDialogLabel: 'Image gallery',
      gallerySlideLabel: 'Image {index} of {total}',
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

  it('renders gallery blocks with the landing carousel UX (lightbox on click)', () => {
    const body = resolvePreviewBlocks(
      [
        {
          type: 'gallery',
          items: [
            { mediaId: 'g1', caption: 'First' },
            { mediaId: 'g2' },
          ],
        },
      ],
      [
        {
          id: 'g1',
          kind: 'inline_image',
          url: 'https://example.com/g1.jpg',
          mimeType: 'image/jpeg',
          fileName: null,
          altText: { en: 'Gallery one' },
        },
        {
          id: 'g2',
          kind: 'inline_image',
          url: 'https://example.com/g2.jpg',
          mimeType: 'image/jpeg',
          fileName: null,
          altText: { en: 'Gallery two' },
        },
      ],
      'en',
    );
    renderBlocks(body);

    const figure = document.querySelector('figure[aria-roledescription="carousel"]');
    expect(figure).toBeTruthy();
    expect(screen.getByText('First')).toBeTruthy();

    fireEvent.click(screen.getByRole('button', { name: 'Gallery one' }));
    const dialog = screen.getByRole('dialog');
    expect(dialog).toBeTruthy();
    expect(screen.getByRole('button', { name: 'Next image' })).toBeTruthy();

    fireEvent.click(screen.getByRole('button', { name: 'Close' }));
    expect(screen.queryByRole('dialog')).toBeNull();
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
