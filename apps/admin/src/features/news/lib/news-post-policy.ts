import type { NewsPostFormValues } from '../types';
import { NEWS_LOCALES } from '../types';
import {
  bodyBlocksValidForPublish,
  coverAltTextForLocale,
  inlineImageAltCompleteForLocale,
} from './news-locale-utils';
import type { NewsMediaDto } from '../news-api-types';
import { hasVisibleText } from '@chisto/news-content';

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
  | 'blockLimit'
  | 'altTextRequired';

function localeLimitsOk(entry: NewsPostFormValues['translations'][typeof NEWS_LOCALES[number]]): NewsValidationErrorKey | null {
  if (entry.title.trim().length > MAX_TITLE_LENGTH) return 'titleTooLong';
  if (entry.excerpt.trim().length > MAX_EXCERPT_LENGTH) return 'excerptTooLong';
  if (entry.body.length > MAX_BODY_BLOCKS) return 'blockLimit';
  return null;
}

export function validateNewsPostForm(
  values: NewsPostFormValues,
  options: {
    mode: 'save' | 'publish';
    hasCover?: boolean;
    media?: NewsMediaDto[];
    /** Scheduled/published posts use the same server rules as publish. */
    requireLiveRules?: boolean;
    /** Draft autosave: allow partial locales even when a schedule date is set. */
    ignoreScheduleRequirements?: boolean;
  },
): NewsValidationErrorKey | null {
  const slug = values.slug.trim();
  if (!slug) return 'slugRequired';
  if (!SLUG_REGEX.test(slug)) return 'slugInvalid';

  const hasSchedule = Boolean(values.scheduledAt.trim());

  for (const locale of NEWS_LOCALES) {
    const limitError = localeLimitsOk(values.translations[locale]);
    if (limitError) return limitError;
  }

  if (hasSchedule && !options.ignoreScheduleRequirements) {
    const scheduled = new Date(values.scheduledAt);
    if (!Number.isNaN(scheduled.getTime()) && scheduled.getTime() < Date.now()) {
      return 'scheduleInPast';
    }
  }

  const requireLocales =
    options.mode === 'publish' ||
    (hasSchedule && !options.ignoreScheduleRequirements) ||
    options.requireLiveRules;

  if (requireLocales) {
    if (!options.hasCover) return 'coverRequired';
    for (const locale of NEWS_LOCALES) {
      const entry = values.translations[locale];
      if (!entry.title.trim()) return 'localeTitleRequired';
      if (!entry.excerpt.trim()) return 'localeExcerptRequired';
      if (!bodyBlocksValidForPublish(entry.body)) {
        if (!entry.body.length) return 'localeBodyRequired';
        for (const block of entry.body) {
          if (block.type === 'paragraph') {
            const text = block.text?.trim() ?? '';
            const html = block.html?.trim();
            const paragraphOk = Boolean(text) || (html ? hasVisibleText(html) : false);
            if (!paragraphOk) return 'emptyParagraph';
          }
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

    if (options.requireLiveRules && options.media) {
      for (const locale of NEWS_LOCALES) {
        const entry = values.translations[locale];
        if (!entry.title.trim()) continue;
        if (!coverAltTextForLocale(options.media, locale)) return 'altTextRequired';
        if (!inlineImageAltCompleteForLocale(entry.body, options.media, locale)) {
          return 'altTextRequired';
        }
      }
    }
  }

  return null;
}

export function newsPostSaveValidationOptions(
  post: { status: 'draft' | 'scheduled' | 'published' | 'archived'; coverMediaId: string | null; media: NewsMediaDto[] },
) {
  const requireLiveRules = post.status === 'scheduled' || post.status === 'published';
  return {
    mode: requireLiveRules ? ('publish' as const) : ('save' as const),
    hasCover: Boolean(post.coverMediaId),
    media: post.media,
    requireLiveRules,
  };
}

export function validateNewsPostForSave(
  values: NewsPostFormValues,
  post: { status: 'draft' | 'scheduled' | 'published' | 'archived'; coverMediaId: string | null; media: NewsMediaDto[] },
): NewsValidationErrorKey | null {
  return validateNewsPostForm(values, newsPostSaveValidationOptions(post));
}

/** Lenient validation for background autosave while drafting. */
export function validateNewsPostForAutosave(
  values: NewsPostFormValues,
  post: { status: 'draft' | 'scheduled' | 'published' | 'archived'; coverMediaId: string | null; media: NewsMediaDto[] },
): NewsValidationErrorKey | null {
  return validateNewsPostForm(values, {
    mode: 'save',
    hasCover: Boolean(post.coverMediaId),
    media: post.media,
    requireLiveRules: post.status === 'scheduled' || post.status === 'published',
    ignoreScheduleRequirements: true,
  });
}
