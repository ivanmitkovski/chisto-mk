import type { NewsPostFormValues } from '../types';
import { NEWS_LOCALES } from '../types';

const SLUG_REGEX = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;

export type NewsValidationErrorKey =
  | 'slugRequired'
  | 'slugInvalid'
  | 'scheduleInPast'
  | 'coverRequired'
  | 'localeTitleRequired'
  | 'localeExcerptRequired'
  | 'localeBodyRequired'
  | 'emptyParagraph'
  | 'mediaIdRequired';

export function validateNewsPostForm(
  values: NewsPostFormValues,
  options: { mode: 'save' | 'publish'; hasCover?: boolean },
): NewsValidationErrorKey | null {
  const slug = values.slug.trim();
  if (!slug) return 'slugRequired';
  if (!SLUG_REGEX.test(slug)) return 'slugInvalid';

  if (values.scheduledAt) {
    const scheduled = new Date(values.scheduledAt);
    if (!Number.isNaN(scheduled.getTime()) && scheduled.getTime() < Date.now()) {
      return 'scheduleInPast';
    }
  }

  if (options.mode === 'publish') {
    if (!options.hasCover) return 'coverRequired';
    for (const locale of NEWS_LOCALES) {
      const entry = values.translations[locale];
      if (!entry.title.trim()) return 'localeTitleRequired';
      if (!entry.excerpt.trim()) return 'localeExcerptRequired';
      if (!entry.body.length) return 'localeBodyRequired';
      for (const block of entry.body) {
        if (block.type === 'paragraph' && !block.text.trim()) return 'emptyParagraph';
        if ((block.type === 'image' || block.type === 'video') && !block.mediaId?.trim()) {
          return 'mediaIdRequired';
        }
      }
    }
  }

  return null;
}
