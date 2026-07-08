/// <reference types="jest" />
import { BadRequestException } from '@nestjs/common';
import {
  assertMediaIntegrity,
  assertScheduledAtNotInPast,
  assertValidSlug,
  assertValidTranslations,
  normalizeSlug,
  paragraphsToBody,
  stripMediaFromTranslations,
} from '../../src/news/services/news-posts-validation';
import type { NewsTranslations } from '../../src/news/types/news.types';
import type { NewsBodyBlock } from '@chisto/news-content';

const completeTranslations = (): NewsTranslations => ({
  en: { title: 'T', excerpt: 'E', body: paragraphsToBody(['p']) },
  mk: { title: 'T', excerpt: 'E', body: paragraphsToBody(['p']) },
  sq: { title: 'T', excerpt: 'E', body: paragraphsToBody(['p']) },
});

describe('news-posts-validation', () => {
  it('normalizes and validates slug', () => {
    expect(normalizeSlug('  Hello World!  ')).toBe('hello-world');
    expect(normalizeSlug('---foo---')).toBe('foo');
    expect(normalizeSlug('-'.repeat(1_000))).toBe('');
    expect(() => assertValidSlug('valid-slug-2026')).not.toThrow();
    expect(() => assertValidSlug('Invalid Slug!')).toThrow(BadRequestException);
  });

  it('converts paragraphs to body blocks', () => {
    const blocks = paragraphsToBody(['Hello', 'World']);
    expect(blocks).toEqual([
      { type: 'paragraph', text: 'Hello' },
      { type: 'paragraph', text: 'World' },
    ]);
  });

  it('blocks publish when a locale is incomplete', () => {
    const incomplete: NewsTranslations = {
      en: { title: 'T', excerpt: 'E', body: paragraphsToBody(['p']) },
      mk: { title: 'T', excerpt: 'E', body: paragraphsToBody(['p']) },
      sq: { title: '', excerpt: 'E', body: paragraphsToBody(['p']) },
    };
    expect(() => assertValidTranslations(incomplete, true)).toThrow(BadRequestException);
  });

  it('allows draft saves with missing locales', () => {
    const partial: NewsTranslations = {
      en: { title: 'T', excerpt: 'E', body: paragraphsToBody(['p']) },
      mk: { title: '', excerpt: '', body: [] },
      sq: { title: '', excerpt: '', body: [] },
    };
    expect(() => assertValidTranslations(partial, false)).not.toThrow();
  });

  it('allows draft saves with empty paragraph placeholders', () => {
    const draft: NewsTranslations = {
      en: { title: 'T', excerpt: 'E', body: [{ type: 'paragraph', text: '' }] },
      mk: { title: '', excerpt: '', body: [] },
      sq: { title: '', excerpt: '', body: [] },
    };
    expect(() => assertValidTranslations(draft, false)).not.toThrow();
  });

  it('allows draft saves with placeholder image blocks missing media id', () => {
    const draft: NewsTranslations = {
      en: {
        title: 'T',
        excerpt: 'E',
        body: [
          { type: 'paragraph', text: 'Hello' },
          { type: 'image', mediaId: '' },
        ],
      },
      mk: { title: '', excerpt: '', body: [] },
      sq: { title: '', excerpt: '', body: [] },
    };
    expect(() => assertValidTranslations(draft, false)).not.toThrow();
  });

  it('rejects schedule in past', () => {
    const past = new Date(Date.now() - 60_000).toISOString();
    expect(() => assertScheduledAtNotInPast(past)).toThrow(BadRequestException);
  });

  it('strips gallery blocks when duplicating translations', () => {
    const translations: NewsTranslations = {
      en: {
        title: 'T',
        excerpt: 'E',
        body: [
          { type: 'paragraph', text: 'Hello' },
          { type: 'gallery', items: [{ mediaId: 'g1' }, { mediaId: 'g2' }] },
        ],
      },
      mk: { title: 'T', excerpt: 'E', body: [] },
      sq: { title: 'T', excerpt: 'E', body: [] },
    };
    const stripped = stripMediaFromTranslations(translations);
    expect(stripped.en.body).toEqual([{ type: 'paragraph', text: 'Hello' }]);
  });

  it('strips media blocks when duplicating translations', () => {
    const translations: NewsTranslations = {
      en: {
        title: 'T',
        excerpt: 'E',
        body: [
          { type: 'paragraph', text: 'Hello' },
          { type: 'heading', level: 2, text: 'Hi' },
          { type: 'html', html: '<p>x</p>' },
          { type: 'image', mediaId: 'm1' },
        ],
      },
      mk: { title: 'T', excerpt: 'E', body: [{ type: 'video', mediaId: 'm2' }] },
      sq: { title: 'T', excerpt: 'E', body: [] },
    };
    const stripped = stripMediaFromTranslations(translations);
    expect(stripped.en.body).toEqual([
      { type: 'paragraph', text: 'Hello' },
      { type: 'heading', level: 2, text: 'Hi' },
      { type: 'html', html: '<p>x</p>' },
    ]);
    expect(stripped.mk.body).toEqual([]);
  });

  it('assertMediaIntegrity rejects missing cover when required', () => {
    expect(() => assertMediaIntegrity(completeTranslations(), [], null)).toThrow(BadRequestException);
  });

  it('assertMediaIntegrity allows missing cover when not required', () => {
    expect(() => assertMediaIntegrity(completeTranslations(), [], null, { requireCover: false })).not.toThrow();
  });

  it('assertMediaIntegrity rejects block type and media kind mismatch', () => {
    const translations: NewsTranslations = {
      ...completeTranslations(),
      en: {
        title: 'T',
        excerpt: 'E',
        body: [{ type: 'video', mediaId: 'm1' }],
      },
    };
    expect(() =>
      assertMediaIntegrity(translations, [{ id: 'cover-1', kind: 'COVER' }, { id: 'm1', kind: 'INLINE_IMAGE' }], 'cover-1'),
    ).toThrow(
      expect.objectContaining({
        response: expect.objectContaining({ code: 'NEWS_MEDIA_KIND_MISMATCH' }),
      }),
    );
  });

  it('assertMediaIntegrity accepts matching inline media kinds', () => {
    const translations: NewsTranslations = {
      ...completeTranslations(),
      en: {
        title: 'T',
        excerpt: 'E',
        body: [
          { type: 'image', mediaId: 'img-1' },
          { type: 'video', mediaId: 'vid-1' },
        ],
      },
    };
    expect(() =>
      assertMediaIntegrity(
        translations,
        [
          { id: 'cover-1', kind: 'COVER' },
          { id: 'img-1', kind: 'INLINE_IMAGE' },
          { id: 'vid-1', kind: 'INLINE_VIDEO' },
        ],
        'cover-1',
      ),
    ).not.toThrow();
  });

  it('assertMediaIntegrity requires alt text on publish when requireAltText is true', () => {
    const translations: NewsTranslations = {
      ...completeTranslations(),
      en: {
        title: 'T',
        excerpt: 'E',
        body: [{ type: 'image', mediaId: 'img-1' }],
      },
    };
    expect(() =>
      assertMediaIntegrity(
        translations,
        [
          { id: 'cover-1', kind: 'COVER', altText: { en: 'Cover alt' } },
          { id: 'img-1', kind: 'INLINE_IMAGE', altText: {} },
        ],
        'cover-1',
        { requireAltText: true },
      ),
    ).toThrow(
      expect.objectContaining({
        response: expect.objectContaining({ code: 'NEWS_ALT_TEXT_REQUIRED' }),
      }),
    );
  });

  it('rejects gallery blocks with fewer than two images on publish', () => {
    const translations: NewsTranslations = {
      ...completeTranslations(),
      en: {
        title: 'T',
        excerpt: 'E',
        body: [{ type: 'gallery', items: [{ mediaId: 'img-1' }] }],
      },
      mk: completeTranslations().mk,
      sq: completeTranslations().sq,
    };
    expect(() => assertValidTranslations(translations, true)).toThrow(BadRequestException);
  });

  it('allows draft saves with in-progress gallery blocks', () => {
    const draft: NewsTranslations = {
      en: {
        title: 'T',
        excerpt: 'E',
        body: [{ type: 'gallery', items: [{ mediaId: 'img-1' }, { mediaId: '' }] }],
      },
      mk: { title: '', excerpt: '', body: [] },
      sq: { title: '', excerpt: '', body: [] },
    };
    expect(() => assertValidTranslations(draft, false)).not.toThrow();
  });

  it('allows draft saves with heading blocks missing level', () => {
    const draft: NewsTranslations = {
      en: {
        title: 'T',
        excerpt: 'E',
        body: [{ type: 'heading', text: 'Section' } as NewsBodyBlock],
      },
      mk: { title: '', excerpt: '', body: [] },
      sq: { title: '', excerpt: '', body: [] },
    };
    expect(() => assertValidTranslations(draft, false)).not.toThrow();
  });

  it('accepts quote, divider, and embed blocks on publish', () => {
    const translations: NewsTranslations = {
      en: {
        title: 'T',
        excerpt: 'E',
        body: [
          { type: 'quote', text: 'A wise line', attribution: 'Author' },
          { type: 'divider' },
          {
            type: 'embed',
            provider: 'youtube',
            url: 'https://www.youtube-nocookie.com/embed/abc123',
          },
        ],
      },
      mk: { title: 'T', excerpt: 'E', body: paragraphsToBody(['p']) },
      sq: { title: 'T', excerpt: 'E', body: paragraphsToBody(['p']) },
    };
    expect(() => assertValidTranslations(translations, true)).not.toThrow();
  });

  it('rejects embed blocks with mismatched provider', () => {
    const translations: NewsTranslations = {
      ...completeTranslations(),
      en: {
        title: 'T',
        excerpt: 'E',
        body: [
          {
            type: 'embed',
            provider: 'vimeo',
            url: 'https://www.youtube-nocookie.com/embed/abc123',
          },
        ],
      },
    };
    expect(() => assertValidTranslations(translations, true)).toThrow(BadRequestException);
  });
});

describe('news translations shape', () => {
  it('matches seed launch structure', () => {
    const translations: NewsTranslations = {
      en: { title: 'T', excerpt: 'E', body: paragraphsToBody(['p']) },
      mk: { title: 'T', excerpt: 'E', body: paragraphsToBody(['p']) },
      sq: { title: 'T', excerpt: 'E', body: paragraphsToBody(['p']) },
    };
    expect(translations.en.body[0]?.type).toBe('paragraph');
  });
});
