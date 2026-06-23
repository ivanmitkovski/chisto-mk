import { BadRequestException } from '@nestjs/common';
import {
  assertValidSlug,
  assertValidTranslations,
  normalizeSlug,
  paragraphsToBody,
} from '../../src/news/services/news-posts-validation';
import type { NewsTranslations } from '../../src/news/types/news.types';

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
