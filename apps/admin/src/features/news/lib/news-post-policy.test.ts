import { describe, expect, it } from 'vitest';
import { validateNewsPostForm, validateNewsPostForSave, validateNewsPostForAutosave } from './news-post-policy';
import { emptyTranslations } from '../types';

describe('news-post-policy', () => {
  it('requires valid slug on save', () => {
    expect(
      validateNewsPostForm(
        {
          slug: 'Invalid Slug',
          category: 'release',
          scheduledAt: '',
          featured: false,
          translations: emptyTranslations(),
        },
        { mode: 'save' },
      ),
    ).toBe('slugInvalid');
  });

  it('blocks publish when locale incomplete', () => {
    const values = {
      slug: 'valid-slug',
      category: 'release' as const,
      scheduledAt: '',
      featured: false,
      translations: emptyTranslations(),
    };
    values.translations.en.title = 'Title';
    expect(validateNewsPostForm(values, { mode: 'publish', hasCover: true })).toBe('localeExcerptRequired');
  });

  it('requires cover on publish', () => {
    const values = {
      slug: 'valid-slug',
      category: 'release' as const,
      scheduledAt: '',
      featured: false,
      translations: emptyTranslations(),
    };
    values.translations.en = {
      title: 'T',
      excerpt: 'E',
      body: [{ type: 'paragraph', text: 'Body' }],
    };
    values.translations.mk = { ...values.translations.en };
    values.translations.sq = { ...values.translations.en };
    expect(validateNewsPostForm(values, { mode: 'publish', hasCover: false })).toBe('coverRequired');
  });

  it('rejects schedule in past', () => {
    const past = new Date(Date.now() - 60_000).toISOString().slice(0, 16);
    expect(
      validateNewsPostForm(
        {
          slug: 'valid-slug',
          category: 'release',
          scheduledAt: past,
          featured: false,
          translations: emptyTranslations(),
        },
        { mode: 'save' },
      ),
    ).toBe('scheduleInPast');
  });

  it('requires publish-ready locales when scheduling', () => {
    const values = {
      slug: 'valid-slug',
      category: 'release' as const,
      scheduledAt: '2099-01-01T10:00',
      featured: false,
      translations: emptyTranslations(),
    };
    values.translations.en.title = 'Title';
    expect(validateNewsPostForm(values, { mode: 'save', hasCover: true })).toBe('localeExcerptRequired');
  });

  it('blocks scheduled post save when cover alt text is missing', () => {
    const values = {
      slug: 'valid-slug',
      category: 'release' as const,
      scheduledAt: '2099-01-01T10:00',
      featured: false,
      translations: emptyTranslations(),
    };
    for (const locale of ['en', 'mk', 'sq'] as const) {
      values.translations[locale] = {
        title: 'Title',
        excerpt: 'Excerpt',
        body: [{ type: 'paragraph', text: 'Body copy' }],
      };
    }

    expect(
      validateNewsPostForSave(values, {
        status: 'scheduled',
        coverMediaId: 'cover-1',
        media: [{ id: 'cover-1', kind: 'cover', url: 'https://example.com/cover.jpg', altText: {} }],
      }),
    ).toBe('altTextRequired');
  });

  it('allows autosave while drafting with a schedule date and partial locales', () => {
    const values = {
      slug: 'valid-slug',
      category: 'release' as const,
      scheduledAt: '2099-01-01T10:00',
      featured: false,
      translations: emptyTranslations(),
    };
    values.translations.en = {
      title: 'Title',
      excerpt: 'Excerpt',
      body: [{ type: 'paragraph', text: 'Body copy' }],
    };

    const post = { status: 'draft' as const, coverMediaId: null, media: [] };

    expect(validateNewsPostForAutosave(values, post)).toBeNull();
    expect(validateNewsPostForSave(values, post)).toBe('coverRequired');
  });

  it('allows autosave while drafting with a past schedule date still in the form', () => {
    const past = new Date(Date.now() - 60_000).toISOString().slice(0, 16);
    const values = {
      slug: 'valid-slug',
      category: 'release' as const,
      scheduledAt: past,
      featured: false,
      translations: emptyTranslations(),
    };
    values.translations.en = {
      title: 'Title',
      excerpt: 'Excerpt',
      body: [{ type: 'paragraph', text: 'Body copy' }],
    };

    expect(
      validateNewsPostForAutosave(values, {
        status: 'draft',
        coverMediaId: null,
        media: [],
      }),
    ).toBeNull();
    expect(
      validateNewsPostForSave(values, {
        status: 'draft',
        coverMediaId: null,
        media: [],
      }),
    ).toBe('scheduleInPast');
  });
});
