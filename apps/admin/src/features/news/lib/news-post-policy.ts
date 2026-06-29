import type { NewsPostFormValues } from '../types';
import { NEWS_LOCALES } from '../types';
import { bodyBlocksValidForPublish } from './news-locale-utils';

const SLUG_REGEX = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;

export const MAX_TITLE_LENGTH = 300;
export const MAX_EXCERPT_LENGTH = 500;
export const MAX_BODY_BLOCKS = 50;

export type NewsValidationErrorKey =
  | 'slugRequired'
  | 'slugInvalid'
  | 'scheduleInPast'
  | 'coverRequired'
  | 'localeTitleRequired'
  | 'localeExcerptRequired'
  | 'localeBodyRequired'
  | 'emptyParagraph'
  | 'mediaIdRequired'
  | 'titleTooLong'
  | 'excerptTooLong'
  | 'blockLimit';

function localeLimitsOk(entry: NewsPostFormValues['translations'][typeof NEWS_LOCALES[number]]): NewsValidationErrorKey | null {
  if (entry.title.trim().length > MAX_TITLE_LENGTH) return 'titleTooLong';
  if (entry.excerpt.trim().length > MAX_EXCERPT_LENGTH) return 'excerptTooLong';
  if (entry.body.length > MAX_BODY_BLOCKS) return 'blockLimit';
  return null;
}

export function validateNewsPostForm(
  values: NewsPostFormValues,
  options: { mode: 'save' | 'publish'; hasCover?: boolean },
): NewsValidationErrorKey | null {
  const slug = values.slug.trim();
  if (!slug) return 'slugRequired';
  if (!SLUG_REGEX.test(slug)) return 'slugInvalid';

  const hasSchedule = Boolean(values.scheduledAt.trim());

  for (const locale of NEWS_LOCALES) {
    const limitError = localeLimitsOk(values.translations[locale]);
    if (limitError) return limitError;
  }

  if (hasSchedule) {
    const scheduled = new Date(values.scheduledAt);
    if (!Number.isNaN(scheduled.getTime()) && scheduled.getTime() < Date.now()) {
      return 'scheduleInPast';
    }
  }

  const requireLocales = options.mode === 'publish' || hasSchedule;

  if (requireLocales) {
    if (!options.hasCover) return 'coverRequired';
    for (const locale of NEWS_LOCALES) {
      const entry = values.translations[locale];
      if (!entry.title.trim()) return 'localeTitleRequired';
      if (!entry.excerpt.trim()) return 'localeExcerptRequired';
      if (!bodyBlocksValidForPublish(entry.body)) {
        if (!entry.body.length) return 'localeBodyRequired';
        for (const block of entry.body) {
          if (block.type === 'paragraph' && !block.text.trim()) return 'emptyParagraph';
          if ((block.type === 'image' || block.type === 'video') && !block.mediaId?.trim()) {
            return 'mediaIdRequired';
          }
          if (block.type === 'gallery') {
            const filled = block.items.filter((i) => i.mediaId?.trim());
            if (filled.length < 2) return 'mediaIdRequired';
          }
        }
      }
    }
  }

  return null;
}
