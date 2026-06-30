import { describe, expect, it } from 'vitest';
import { buildCreateNewsInput } from './build-create-news-input';
import { emptyTranslations } from '../types';

describe('buildCreateNewsInput', () => {
  it('strips admin-only form fields and fills locales for create', () => {
    const payload = buildCreateNewsInput({
      slug: '',
      category: 'release',
      translations: {
        ...emptyTranslations(),
        en: { title: 'test', excerpt: '', body: [] },
      },
    });

    expect(payload).toEqual({
      category: 'release',
      translations: {
        en: {
          title: 'test',
          excerpt: 'test',
          body: [{ type: 'paragraph', text: 'test' }],
        },
        mk: {
          title: 'test',
          excerpt: 'test',
          body: [{ type: 'paragraph', text: 'test' }],
        },
        sq: {
          title: 'test',
          excerpt: 'test',
          body: [{ type: 'paragraph', text: 'test' }],
        },
      },
    });
    expect(payload).not.toHaveProperty('scheduledAt');
    expect(payload).not.toHaveProperty('featured');
    expect(payload).not.toHaveProperty('slug');
  });

  it('strips client-only block ids from template bodies', () => {
    const payload = buildCreateNewsInput({
      category: 'release',
      translations: {
        ...emptyTranslations(),
        en: {
          title: 'test',
          excerpt: '',
          body: [{ id: 'client-only', type: 'paragraph', text: 'Hello' }],
        },
      },
    });

    expect(payload.translations.en.body).toEqual([{ type: 'paragraph', text: 'Hello' }]);
  });

  it('keeps a trimmed slug when provided', () => {
    const payload = buildCreateNewsInput({
      slug: '  my-slug  ',
      category: 'product',
      translations: {
        ...emptyTranslations(),
        en: { title: 'Title', excerpt: '', body: [] },
      },
    });

    expect(payload.slug).toBe('my-slug');
  });
});
