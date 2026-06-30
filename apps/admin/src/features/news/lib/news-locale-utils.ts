'use client';

import { galleryHasContent, hasVisibleText, htmlBlockHasContent } from '@chisto/news-content';
import type { NewsBodyBlock, NewsMediaDto, NewsPostAdminDto } from '../news-api-types';
import type { NewsFormLocale, NewsPostFormValues } from '../types';
import { NEWS_LOCALES } from '../types';
import { MAX_BODY_BLOCKS, MAX_EXCERPT_LENGTH, MAX_TITLE_LENGTH } from './news-post-policy';

export type LocalePublishChecklistItem = 'title' | 'excerpt' | 'body' | 'cover' | 'altText' | 'limits';

function paragraphValid(block: Extract<NewsBodyBlock, { type: 'paragraph' }>): boolean {
  if (block.text.trim()) return true;
  const html = block.html?.trim();
  return html ? hasVisibleText(html) : false;
}

export function bodyBlocksValidForPublish(body: NewsBodyBlock[]): boolean {
  return (
    body.length > 0 &&
    body.every((b) => {
      if (b.type === 'paragraph') return paragraphValid(b);
      if (b.type === 'html') return htmlBlockHasContent(b.html);
      if (b.type === 'heading') return Boolean(b.text.trim());
      if (b.type === 'list') return b.items.some((item) => item.trim());
      if (b.type === 'image' || b.type === 'video') return Boolean(b.mediaId.trim());
      if (b.type === 'gallery') return galleryHasContent(b) && b.items.filter((i) => i.mediaId?.trim()).length >= 2;
      return false;
    })
  );
}

function localeContentLimitsOk(entry: NewsPostFormValues['translations'][NewsFormLocale]): boolean {
  return (
    entry.title.trim().length <= MAX_TITLE_LENGTH &&
    entry.excerpt.trim().length <= MAX_EXCERPT_LENGTH &&
    entry.body.length <= MAX_BODY_BLOCKS
  );
}

export function localePublishChecklist(
  values: NewsPostFormValues,
  locale: NewsFormLocale,
  hasCover: boolean,
  media: NewsMediaDto[],
): { item: LocalePublishChecklistItem; ok: boolean }[] {
  const entry = values.translations[locale];
  const bodyOk = bodyBlocksValidForPublish(entry.body);
  const altOk =
    coverAltTextForLocale(media, locale) && inlineImageAltCompleteForLocale(entry.body, media, locale);

  return [
    { item: 'title', ok: Boolean(entry.title.trim()) },
    { item: 'excerpt', ok: Boolean(entry.excerpt.trim()) },
    { item: 'body', ok: bodyOk },
    { item: 'cover', ok: hasCover },
    { item: 'altText', ok: altOk },
    { item: 'limits', ok: localeContentLimitsOk(entry) },
  ];
}

export function localePublishReady(
  values: NewsPostFormValues,
  locale: NewsFormLocale,
  hasCover: boolean,
  media: NewsMediaDto[] = [],
): boolean {
  return localePublishChecklist(values, locale, hasCover, media).every((item) => item.ok);
}

export function allLocalesPublishReady(
  values: NewsPostFormValues,
  hasCover: boolean,
  media: NewsMediaDto[] = [],
): boolean {
  return NEWS_LOCALES.every((locale) => localePublishReady(values, locale, hasCover, media));
}

export function countIncompleteLocales(
  values: NewsPostFormValues,
  hasCover: boolean,
  media: NewsMediaDto[] = [],
): number {
  return NEWS_LOCALES.filter((locale) => !localePublishReady(values, locale, hasCover, media)).length;
}


export function localeCompleteness(
  values: NewsPostFormValues,
  hasCover: boolean,
  media: NewsMediaDto[] = [],
): Record<(typeof NEWS_LOCALES)[number], boolean> {
  const out = {} as Record<(typeof NEWS_LOCALES)[number], boolean>;
  for (const locale of NEWS_LOCALES) {
    out[locale] = localePublishReady(values, locale, hasCover, media);
  }
  return out;
}

export function countCompleteLocales(
  values: NewsPostFormValues,
  hasCover: boolean,
  media: NewsMediaDto[] = [],
): number {
  const scores = localeCompleteness(values, hasCover, media);
  return NEWS_LOCALES.filter((l) => scores[l]).length;
}

export function countsByStatus(posts: NewsPostAdminDto[] | null | undefined) {
  return (posts ?? []).reduce(
    (acc, p) => {
      acc[p.status] = (acc[p.status] ?? 0) + 1;
      return acc;
    },
    {} as Record<string, number>,
  );
}

export function mediaReferencedInBody(
  mediaId: string,
  translations: NewsPostFormValues['translations'],
): boolean {
  for (const locale of NEWS_LOCALES) {
    for (const block of translations[locale].body) {
      if ((block.type === 'image' || block.type === 'video') && block.mediaId === mediaId) {
        return true;
      }
      if (block.type === 'gallery' && block.items.some((item) => item.mediaId === mediaId)) {
        return true;
      }
    }
  }
  return false;
}

function altForLocale(
  altText: Partial<Record<string, string>> | null | undefined,
  locale: (typeof NEWS_LOCALES)[number],
): string {
  return (altText?.[locale] ?? altText?.en ?? '').trim();
}

export function coverAltTextForLocale(
  media: NewsMediaDto[],
  locale: (typeof NEWS_LOCALES)[number],
): boolean {
  const cover = media.find((m) => m.kind === 'cover');
  if (!cover) return false;
  return Boolean(altForLocale(cover.altText, locale));
}

export function inlineImageAltCompleteForLocale(
  body: NewsBodyBlock[],
  media: NewsMediaDto[],
  locale: (typeof NEWS_LOCALES)[number],
): boolean {
  const mediaById = new Map(media.map((m) => [m.id, m]));
  for (const block of body) {
    if (block.type === 'image') {
      const item = mediaById.get(block.mediaId);
      if (!item) return false;
      if (!altForLocale(item.altText, locale)) return false;
    }
    if (block.type === 'gallery') {
      for (const galleryItem of block.items) {
        if (!galleryItem.mediaId.trim()) continue;
        const item = mediaById.get(galleryItem.mediaId);
        if (!item) return false;
        if (!altForLocale(item.altText, locale)) return false;
      }
    }
  }
  return true;
}
