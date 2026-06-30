import { BadRequestException } from '@nestjs/common';
import type { NewsMediaKind } from '../../prisma-client';
import {
  htmlBlockHasContent,
  MAX_GALLERY_CAPTION_LENGTH,
  MAX_GALLERY_ITEMS,
  MIN_GALLERY_ITEMS,
  type NewsBodyBlock,
} from '@chisto/news-content';
import type { NewsCategoryApi } from '../types/news.types';
import { NEWS_LOCALES, type NewsTranslations } from '../types/news.types';
import { paragraphHasContent, paragraphPlainText } from './news-content-sanitize.service';

const SLUG_REGEX = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;
const MAX_TITLE_LENGTH = 300;
const MAX_EXCERPT_LENGTH = 500;
const MAX_PARAGRAPH_LENGTH = 10_000;
const MAX_PARAGRAPH_HTML_LENGTH = 15_000;
const MAX_HTML_BLOCK_LENGTH = 20_000;
const MAX_HEADING_LENGTH = 200;
const MAX_LIST_ITEMS = 20;
const MAX_LIST_ITEM_LENGTH = 500;
const MAX_CAPTION_LENGTH = 500;
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
    if (!paragraphHasContent(block)) {
      throw new BadRequestException({
        code: 'NEWS_EMPTY_PARAGRAPH',
        message: `Body block ${index + 1} paragraph text is required`,
      });
    }
    const plain = paragraphPlainText(block);
    if (plain.length > MAX_PARAGRAPH_LENGTH) {
      throw new BadRequestException({
        code: 'NEWS_PARAGRAPH_TOO_LONG',
        message: `Body block ${index + 1} exceeds maximum length`,
      });
    }
    const htmlLen = block.html?.length ?? 0;
    if (htmlLen > MAX_PARAGRAPH_HTML_LENGTH) {
      throw new BadRequestException({
        code: 'NEWS_PARAGRAPH_HTML_TOO_LONG',
        message: `Body block ${index + 1} rich content exceeds maximum length`,
      });
    }
    return;
  }

  if (block.type === 'html') {
    const html = block.html?.trim() ?? '';
    if (!html || !htmlBlockHasContent(html)) {
      throw new BadRequestException({
        code: 'NEWS_EMPTY_HTML_BLOCK',
        message: `Body block ${index + 1} HTML content is required`,
      });
    }
    if (html.length > MAX_HTML_BLOCK_LENGTH) {
      throw new BadRequestException({
        code: 'NEWS_HTML_BLOCK_TOO_LONG',
        message: `Body block ${index + 1} HTML exceeds maximum length`,
      });
    }
    return;
  }

  if (block.type === 'heading') {
    const text = block.text?.trim() ?? '';
    if (!text) {
      throw new BadRequestException({
        code: 'NEWS_EMPTY_HEADING',
        message: `Body block ${index + 1} heading text is required`,
      });
    }
    if (text.length > MAX_HEADING_LENGTH) {
      throw new BadRequestException({
        code: 'NEWS_HEADING_TOO_LONG',
        message: `Body block ${index + 1} heading exceeds maximum length`,
      });
    }
    if (block.level !== 2 && block.level !== 3) {
      throw new BadRequestException({
        code: 'NEWS_INVALID_HEADING_LEVEL',
        message: `Body block ${index + 1} heading level must be 2 or 3`,
      });
    }
    return;
  }

  if (block.type === 'list') {
    const items = block.items?.filter((item) => item.trim()) ?? [];
    if (items.length === 0) {
      throw new BadRequestException({
        code: 'NEWS_EMPTY_LIST',
        message: `Body block ${index + 1} list must have at least one item`,
      });
    }
    if (items.length > MAX_LIST_ITEMS) {
      throw new BadRequestException({
        code: 'NEWS_LIST_TOO_MANY_ITEMS',
        message: `Body block ${index + 1} list has too many items`,
      });
    }
    for (const item of items) {
      if (item.length > MAX_LIST_ITEM_LENGTH) {
        throw new BadRequestException({
          code: 'NEWS_LIST_ITEM_TOO_LONG',
          message: `Body block ${index + 1} list item exceeds maximum length`,
        });
      }
    }
    return;
  }

  if (block.type === 'gallery') {
    const items = block.items?.filter((item) => item.mediaId?.trim()) ?? [];
    if (items.length < MIN_GALLERY_ITEMS) {
      throw new BadRequestException({
        code: 'NEWS_GALLERY_TOO_FEW_ITEMS',
        message: `Body block ${index + 1} gallery must have at least ${MIN_GALLERY_ITEMS} images`,
      });
    }
    if (items.length > MAX_GALLERY_ITEMS) {
      throw new BadRequestException({
        code: 'NEWS_GALLERY_TOO_MANY_ITEMS',
        message: `Body block ${index + 1} gallery has too many images`,
      });
    }
    for (const item of items) {
      if ((item.caption?.trim() ?? '').length > MAX_GALLERY_CAPTION_LENGTH) {
        throw new BadRequestException({
          code: 'NEWS_CAPTION_TOO_LONG',
          message: `Body block ${index + 1} gallery caption exceeds maximum length`,
        });
      }
    }
    return;
  }

  if (!block.mediaId?.trim()) {
    throw new BadRequestException({
      code: 'NEWS_MEDIA_ID_REQUIRED',
      message: `Body block ${index + 1} requires a media id`,
    });
  }

  const caption = block.caption?.trim() ?? '';
  if (caption.length > MAX_CAPTION_LENGTH) {
    throw new BadRequestException({
      code: 'NEWS_CAPTION_TOO_LONG',
      message: `Body block ${index + 1} caption exceeds maximum length`,
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
    entry.body?.forEach((block, i) => {
      if (!requireComplete && block.type === 'paragraph' && !paragraphHasContent(block)) {
        return;
      }
      if (!requireComplete && block.type === 'html' && !htmlBlockHasContent(block.html ?? '')) {
        return;
      }
      if (!requireComplete && block.type === 'heading') {
        if (!block.text?.trim()) return;
        if (block.level !== 2 && block.level !== 3) return;
      }
      if (!requireComplete && block.type === 'list' && !(block.items?.some((item) => item.trim()))) {
        return;
      }
      if (
        !requireComplete &&
        (block.type === 'image' || block.type === 'video') &&
        !block.mediaId?.trim()
      ) {
        return;
      }
      if (!requireComplete && block.type === 'gallery') {
        const filled = block.items?.filter((item) => item.mediaId?.trim()).length ?? 0;
        if (filled < MIN_GALLERY_ITEMS) return;
      }
      assertBodyBlock(block, i);
    });
  }
}

export function coalesceDraftTranslations(input: {
  en?: { title?: string; excerpt?: string; body?: NewsBodyBlock[] };
  mk?: { title?: string; excerpt?: string; body?: NewsBodyBlock[] };
  sq?: { title?: string; excerpt?: string; body?: NewsBodyBlock[] };
}): NewsTranslations {
  const out = {} as NewsTranslations;
  for (const locale of NEWS_LOCALES) {
    const entry = input[locale] ?? {};
    out[locale] = {
      title: entry.title ?? '',
      excerpt: entry.excerpt ?? '',
      body: entry.body?.length ? entry.body : [],
    };
  }
  return out;
}

export function paragraphsToBody(paragraphs: string[]): NewsBodyBlock[] {
  return paragraphs.map((text) => ({ type: 'paragraph' as const, text }));
}

export function assertScheduledAtNotInPast(scheduledAt: string | null | undefined): void {
  if (!scheduledAt) return;
  const date = new Date(scheduledAt);
  if (Number.isNaN(date.getTime())) {
    throw new BadRequestException({
      code: 'NEWS_INVALID_SCHEDULE',
      message: 'Invalid schedule date',
    });
  }
  if (date.getTime() < Date.now()) {
    throw new BadRequestException({
      code: 'NEWS_SCHEDULE_IN_PAST',
      message: 'Scheduled publish time must be in the future',
    });
  }
}

type NewsMediaRef = {
  id: string;
  kind: NewsMediaKind;
  altText?: unknown;
};

function altForMediaRef(altText: NewsMediaRef['altText'], locale: string): string {
  const record = altText as Partial<Record<string, string>> | null | undefined;
  return (record?.[locale]?.trim() ?? record?.en?.trim() ?? '');
}

export type AssertMediaIntegrityOptions = {
  /** When false, inline body media is still checked but cover is not required (editing live posts). */
  requireCover?: boolean;
  /** When true, require non-empty alt text for cover and inline images per locale with content. */
  requireAltText?: boolean;
};

export function assertMediaIntegrity(
  translations: NewsTranslations,
  media: NewsMediaRef[],
  coverMediaId: string | null,
  options: AssertMediaIntegrityOptions = {},
): void {
  const requireCover = options.requireCover ?? true;
  const requireAltText = options.requireAltText ?? false;

  if (requireCover && !coverMediaId) {
    throw new BadRequestException({
      code: 'NEWS_COVER_REQUIRED',
      message: 'Cover image is required before publishing',
    });
  }

  const mediaById = new Map(media.map((m) => [m.id, m]));

  if (coverMediaId) {
    const cover = mediaById.get(coverMediaId);
    if (!cover) {
      throw new BadRequestException({
        code: 'NEWS_MEDIA_NOT_FOUND',
        message: `Cover media ${coverMediaId} is not attached to this post`,
      });
    }
    if (cover.kind === 'INLINE_VIDEO') {
      throw new BadRequestException({
        code: 'NEWS_COVER_MUST_BE_IMAGE',
        message: 'Cover must be an image file',
      });
    }
  }

  for (const locale of NEWS_LOCALES) {
    const entry = translations[locale];
    if (!entry?.body) continue;
    const localeHasContent = Boolean(entry.title?.trim());

    if (requireAltText && coverMediaId && localeHasContent) {
      const cover = mediaById.get(coverMediaId);
      const alt = altForMediaRef(cover?.altText, locale);
      if (!alt) {
        throw new BadRequestException({
          code: 'NEWS_ALT_TEXT_REQUIRED',
          message: `Cover alt text is required for locale ${locale}`,
        });
      }
    }

    for (const block of entry.body) {
      if (block.type === 'paragraph' || block.type === 'html' || block.type === 'heading' || block.type === 'list') {
        continue;
      }

      if (block.type === 'gallery') {
        for (const item of block.items) {
          if (!item.mediaId?.trim()) continue;
          const ref = mediaById.get(item.mediaId);
          if (!ref) {
            throw new BadRequestException({
              code: 'NEWS_MEDIA_NOT_FOUND',
              message: `Media ${item.mediaId} is not attached to this post`,
            });
          }
          if (ref.kind !== 'INLINE_IMAGE') {
            throw new BadRequestException({
              code: 'NEWS_MEDIA_KIND_MISMATCH',
              message: `Gallery item media kind must be image for ${item.mediaId}`,
            });
          }
          if (requireAltText && localeHasContent) {
            const alt = altForMediaRef(ref.altText, locale);
            if (!alt) {
              throw new BadRequestException({
                code: 'NEWS_ALT_TEXT_REQUIRED',
                message: `Alt text is required for gallery image ${item.mediaId} (${locale})`,
              });
            }
          }
        }
        continue;
      }

      const kind = mediaById.get(block.mediaId);
      if (!kind) {
        throw new BadRequestException({
          code: 'NEWS_MEDIA_NOT_FOUND',
          message: `Media ${block.mediaId} is not attached to this post`,
        });
      }

      const expectedKind: NewsMediaKind = block.type === 'image' ? 'INLINE_IMAGE' : 'INLINE_VIDEO';
      if (kind.kind !== expectedKind) {
        throw new BadRequestException({
          code: 'NEWS_MEDIA_KIND_MISMATCH',
          message: `Body block media kind does not match block type for ${block.mediaId}`,
        });
      }

      if (requireAltText && block.type === 'image' && localeHasContent) {
        const alt = altForMediaRef(kind.altText, locale);
        if (!alt) {
          throw new BadRequestException({
            code: 'NEWS_ALT_TEXT_REQUIRED',
            message: `Alt text is required for image ${block.mediaId} (${locale})`,
          });
        }
      }
    }
  }
}

/** Removes image/video blocks so duplicated drafts do not reference source media. */
export function stripMediaFromTranslations(translations: NewsTranslations): NewsTranslations {
  const out = {} as NewsTranslations;
  for (const locale of NEWS_LOCALES) {
    const entry = translations[locale];
    out[locale] = {
      title: entry.title,
      excerpt: entry.excerpt,
      body: entry.body.filter(
        (block) =>
          block.type === 'paragraph' ||
          block.type === 'html' ||
          block.type === 'heading' ||
          block.type === 'list',
      ),
    };
  }
  return out;
}

/** Removes a single media id from body blocks across all locales. */
export function stripMediaIdFromTranslations(
  translations: NewsTranslations,
  mediaId: string,
): NewsTranslations {
  const out = {} as NewsTranslations;
  for (const locale of NEWS_LOCALES) {
    const entry = translations[locale];
    out[locale] = {
      title: entry.title,
      excerpt: entry.excerpt,
      body: entry.body
        .map((block) => {
          if (block.type !== 'gallery') return block;
          return {
            ...block,
            items: block.items.filter((item) => item.mediaId !== mediaId),
          };
        })
        .filter((block) => {
          if (block.type === 'paragraph' || block.type === 'html' || block.type === 'heading' || block.type === 'list') {
            return true;
          }
          if (block.type === 'gallery') {
            const filled = block.items?.filter((item) => item.mediaId?.trim()).length ?? 0;
            return filled >= MIN_GALLERY_ITEMS;
          }
          return block.mediaId !== mediaId;
        }),
    };
  }
  return out;
}
