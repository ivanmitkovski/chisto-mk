import { describe, expect, it } from 'vitest';
import { lintNewsContent, readingStatsFromBlocks } from './news-content-lint';
import { bodyBlocksValidForPublish } from './news-locale-utils';
import type { NewsPostFormValues } from '../types';

const emptyValues = (): NewsPostFormValues => ({
  slug: 'post',
  category: 'release',
  scheduledAt: '',
  featured: false,
  translations: {
    en: { title: '', excerpt: '', body: [] },
    mk: { title: '', excerpt: '', body: [] },
    sq: { title: '', excerpt: '', body: [] },
  },
});

describe('bodyBlocksValidForPublish', () => {
  it('accepts quote, divider, and embed blocks', () => {
    expect(
      bodyBlocksValidForPublish([
        { type: 'quote', text: 'Wise words' },
        { type: 'divider' },
        { type: 'embed', provider: 'youtube', url: 'https://www.youtube-nocookie.com/embed/x' },
      ]),
    ).toBe(true);
  });
});

describe('lintNewsContent', () => {
  it('flags missing title and cover', () => {
    const issues = lintNewsContent(emptyValues(), false, []);
    expect(issues.some((issue) => issue.id === 'titleMissing')).toBe(true);
    expect(issues.some((issue) => issue.id === 'coverMissing')).toBe(true);
  });

  it('does not emit duplicate bodyInvalid keys for the same locale', () => {
    const values = emptyValues();
    values.translations.en = {
      title: 'Title',
      excerpt: 'Excerpt',
      body: [
        { type: 'paragraph', text: '' },
        { type: 'paragraph', text: 'Valid paragraph' },
      ],
    };

    const issues = lintNewsContent(values, true, []);
    const bodyInvalid = issues.filter((issue) => issue.id === 'bodyInvalid' && issue.locale === 'en');
    expect(bodyInvalid).toHaveLength(1);
  });
});

describe('readingStatsFromBlocks', () => {
  it('estimates reading time from body text', () => {
    const stats = readingStatsFromBlocks([
      { type: 'paragraph', text: 'one two three four five six seven eight nine ten' },
    ]);
    expect(stats.wordCount).toBe(10);
    expect(stats.readingMinutes).toBeGreaterThanOrEqual(1);
  });
});
