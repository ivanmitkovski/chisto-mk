/// <reference types="jest" />
import { normalizeTranslationsBody } from '../../src/news/services/news-content-sanitize.service';
import {
  assertValidTranslations,
  paragraphsToBody,
} from '../../src/news/services/news-posts-validation';
import type { NewsTranslations } from '../../src/news/types/news.types';

const completeTranslations = (): NewsTranslations => ({
  en: { title: 'T', excerpt: 'E', body: paragraphsToBody(['p']) },
  mk: { title: 'T', excerpt: 'E', body: paragraphsToBody(['p']) },
  sq: { title: 'T', excerpt: 'E', body: paragraphsToBody(['p']) },
});

describe('news-content-sanitize.service', () => {
  it('sanitizes rich paragraph html and assigns block ids on write', () => {
    const translations = completeTranslations();
    translations.en.body = [
      {
        type: 'paragraph',
        text: 'Click here',
        html: '<p>Click <a href="https://example.com">here</a></p><script>alert(1)</script>',
      },
    ];
    const normalized = normalizeTranslationsBody(translations);
    const paragraph = normalized.en.body[0];
    expect(paragraph.type).toBe('paragraph');
    if (paragraph.type !== 'paragraph') throw new Error('expected paragraph');
    expect(paragraph.html).toContain('https://example.com');
    expect(paragraph.html).not.toContain('script');
  });

  it('sanitizes html blocks and strips untrusted iframes', () => {
    const translations = completeTranslations();
    translations.en.body = [
      {
        type: 'html',
        html: '<p>Safe</p><iframe src="https://evil.com/x"></iframe>',
      },
    ];
    const normalized = normalizeTranslationsBody(translations);
    const htmlBlock = normalized.en.body[0];
    expect(htmlBlock.type).toBe('html');
    if (htmlBlock.type !== 'html') throw new Error('expected html');
    expect(htmlBlock.html).toContain('Safe');
    expect(htmlBlock.html).not.toContain('evil.com');
  });
});

describe('news-posts-validation extended blocks', () => {
  it('accepts heading and list blocks on publish', () => {
    const translations: NewsTranslations = {
      en: {
        title: 'T',
        excerpt: 'E',
        body: [
          { type: 'heading', level: 2, text: 'Section' },
          { type: 'list', ordered: false, items: ['One', 'Two'] },
        ],
      },
      mk: { title: 'T', excerpt: 'E', body: paragraphsToBody(['p']) },
      sq: { title: 'T', excerpt: 'E', body: paragraphsToBody(['p']) },
    };
    expect(() => assertValidTranslations(translations, true)).not.toThrow();
  });

  it('rejects empty list on publish', () => {
    const translations: NewsTranslations = {
      ...completeTranslations(),
      en: {
        title: 'T',
        excerpt: 'E',
        body: [{ type: 'list', ordered: false, items: ['  '] }],
      },
    };
    expect(() => assertValidTranslations(translations, true)).toThrow();
  });
});
