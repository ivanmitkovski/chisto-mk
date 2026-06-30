import { buildEmbedIframeHtml } from '@chisto/news-content';
import { describe, expect, it } from 'vitest';
import { newsFormSaveFingerprint, prepareNewsSavePayload } from './news-save-payload';
import type { NewsBodyBlock, NewsPostFormValues } from '../types';

const baseValues = (): NewsPostFormValues => ({
  slug: 'launch-post',
  category: 'release',
  scheduledAt: '',
  featured: true,
  translations: {
    en: {
      title: 'Title',
      excerpt: 'Excerpt',
      body: [{ id: 'client-id-1', type: 'paragraph', text: 'Hello world' }],
    },
    mk: { title: 'T', excerpt: 'E', body: [] },
    sq: { title: 'T', excerpt: 'E', body: [] },
  },
});

describe('prepareNewsSavePayload', () => {
  it('strips client block ids and redundant paragraph html', () => {
    const values = baseValues();
    values.translations.en.body = [
      { id: 'client-id-1', type: 'paragraph', text: 'Hello world', html: '<p>Hello world</p>' },
    ];

    expect(prepareNewsSavePayload(values).translations.en.body).toEqual([
      { type: 'paragraph', text: 'Hello world' },
    ]);
  });

  it('treats tipTap html wrapping as unchanged for fingerprint', () => {
    const plain = baseValues();
    const withHtml = baseValues();
    withHtml.translations.en.body = [
      { id: 'another-id', type: 'paragraph', text: 'Hello world', html: '<p>Hello world</p>' },
    ];

    expect(newsFormSaveFingerprint(plain)).toBe(newsFormSaveFingerprint(withHtml));
  });

  it('preserves iframe-only html blocks in save payload', () => {
    const embed = buildEmbedIframeHtml('https://www.youtube-nocookie.com/embed/abc123');
    const values = baseValues();
    values.translations.en.body = [{ type: 'html', html: embed }];

    const block = prepareNewsSavePayload(values).translations.en.body[0];
    expect(block?.type).toBe('html');
    if (block?.type === 'html') {
      expect(block.html).toContain('iframe');
    }
  });

  it('omits in-progress gallery blocks from save payload', () => {
    const values = baseValues();
    values.translations.en.body = [
      { type: 'paragraph', text: 'Hello' },
      { type: 'gallery', items: [{ mediaId: 'img-1' }, { mediaId: '' }] },
    ];

    expect(prepareNewsSavePayload(values).translations.en.body).toEqual([
      { type: 'paragraph', text: 'Hello' },
    ]);
  });

  it('defaults heading level when missing', () => {
    const values = baseValues();
    values.translations.en.body = [{ type: 'heading', text: 'Section' } as NewsBodyBlock];

    expect(prepareNewsSavePayload(values).translations.en.body).toEqual([
      { type: 'heading', level: 2, text: 'Section' },
    ]);
  });
});
