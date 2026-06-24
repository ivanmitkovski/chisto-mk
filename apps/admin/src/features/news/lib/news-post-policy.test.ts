import { describe, expect, it } from 'vitest';
import { validateNewsPostForm } from './news-post-policy';
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
});
