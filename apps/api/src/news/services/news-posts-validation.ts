import { BadRequestException } from '@nestjs/common';
import type { NewsCategoryApi } from '../types/news.types';
import { NEWS_LOCALES, type NewsBodyBlock, type NewsTranslations } from '../types/news.types';

const SLUG_REGEX = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;
const MAX_TITLE_LENGTH = 300;
const MAX_EXCERPT_LENGTH = 500;
const MAX_PARAGRAPH_LENGTH = 10_000;
const MAX_BODY_BLOCKS = 50;
const HYPHEN_CODE = '-'.charCodeAt(0);

/** Linear-time trim; avoids polynomial regex on user-controlled slug input. */
function trimEdgeHyphens(value: string): string {
  let start = 0;
  let end = value.length;
  while (start < end && value.charCodeAt(start) === HYPHEN_CODE) start += 1;
  while (end > start && value.charCodeAt(end - 1) === HYPHEN_CODE) end -= 1;
  return value.slice(start, end);
}

export function normalizeSlug(input: string): string {
  const normalized = input
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-');
  return trimEdgeHyphens(normalized).slice(0, 120);
}

export function assertValidSlug(slug: string): void {
  if (!slug || !SLUG_REGEX.test(slug)) {
    throw new BadRequestException({
      code: 'NEWS_INVALID_SLUG',
      message: 'Slug must be lowercase letters, numbers, and hyphens only',
    });
  }
}

export function assertValidCategory(category: NewsCategoryApi): void {
  const allowed: NewsCategoryApi[] = ['release', 'partnership', 'community', 'product'];
  if (!allowed.includes(category)) {
    throw new BadRequestException({
      code: 'NEWS_INVALID_CATEGORY',
      message: 'Invalid news category',
    });
  }
}

function assertBodyBlock(block: NewsBodyBlock, index: number): void {
  if (block.type === 'paragraph') {
    const text = block.text?.trim() ?? '';
    if (!text) {
      throw new BadRequestException({
        code: 'NEWS_EMPTY_PARAGRAPH',
        message: `Body block ${index + 1} paragraph text is required`,
      });
    }
    if (text.length > MAX_PARAGRAPH_LENGTH) {
      throw new BadRequestException({
        code: 'NEWS_PARAGRAPH_TOO_LONG',
        message: `Body block ${index + 1} exceeds maximum length`,
      });
    }
    return;
  }
  if (!block.mediaId?.trim()) {
    throw new BadRequestException({
      code: 'NEWS_MEDIA_ID_REQUIRED',
      message: `Body block ${index + 1} requires a media id`,
    });
  }
}

export function assertValidTranslations(translations: NewsTranslations, requireComplete: boolean): void {
  for (const locale of NEWS_LOCALES) {
    const entry = translations[locale];
    if (!entry) {
      if (requireComplete) {
        throw new BadRequestException({
          code: 'NEWS_LOCALE_REQUIRED',
          message: `Content for locale ${locale} is required`,
        });
      }
      continue;
    }
    const title = entry.title?.trim() ?? '';
    const excerpt = entry.excerpt?.trim() ?? '';
    if (requireComplete && !title) {
      throw new BadRequestException({
        code: 'NEWS_TITLE_REQUIRED',
        message: `Title for locale ${locale} is required`,
      });
    }
    if (requireComplete && !excerpt) {
      throw new BadRequestException({
        code: 'NEWS_EXCERPT_REQUIRED',
        message: `Excerpt for locale ${locale} is required`,
      });
    }
    if (title.length > MAX_TITLE_LENGTH) {
      throw new BadRequestException({
        code: 'NEWS_TITLE_TOO_LONG',
        message: `Title for locale ${locale} is too long`,
      });
    }
    if (excerpt.length > MAX_EXCERPT_LENGTH) {
      throw new BadRequestException({
        code: 'NEWS_EXCERPT_TOO_LONG',
        message: `Excerpt for locale ${locale} is too long`,
      });
    }
    if (requireComplete && (!entry.body || entry.body.length === 0)) {
      throw new BadRequestException({
        code: 'NEWS_BODY_REQUIRED',
        message: `At least one body block for locale ${locale} is required`,
      });
    }
    if (entry.body && entry.body.length > MAX_BODY_BLOCKS) {
      throw new BadRequestException({
        code: 'NEWS_BODY_TOO_MANY_BLOCKS',
        message: `Too many body blocks for locale ${locale}`,
      });
    }
    entry.body?.forEach((block, i) => assertBodyBlock(block, i));
  }
}

export function paragraphsToBody(paragraphs: string[]): NewsBodyBlock[] {
  return paragraphs.map((text) => ({ type: 'paragraph' as const, text }));
}
