'use client';

import type { NewsPostAdminDto } from '../news-api-types';
import type { NewsPostFormValues } from '../types';
import { NEWS_LOCALES } from '../types';

export function localeCompleteness(
  values: NewsPostFormValues,
  hasCover: boolean,
): Record<(typeof NEWS_LOCALES)[number], boolean> {
  const out = {} as Record<(typeof NEWS_LOCALES)[number], boolean>;
  for (const locale of NEWS_LOCALES) {
    const entry = values.translations[locale];
    out[locale] =
      Boolean(entry.title.trim()) &&
      Boolean(entry.excerpt.trim()) &&
      entry.body.length > 0 &&
      entry.body.every(
        (b) =>
          (b.type === 'paragraph' && b.text.trim()) ||
          ((b.type === 'image' || b.type === 'video') && b.mediaId.trim()),
      ) &&
      hasCover;
  }
  return out;
}

export function countCompleteLocales(
  values: NewsPostFormValues,
  hasCover: boolean,
): number {
  const scores = localeCompleteness(values, hasCover);
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
    }
  }
  return false;
}
