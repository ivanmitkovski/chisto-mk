import { ApiError } from '@/lib/api/api';

const CODE_TO_I18N: Record<string, string> = {
  NEWS_SLUG_TAKEN: 'apiErrors.slugTaken',
  NEWS_INVALID_SLUG: 'apiErrors.invalidSlug',
  NEWS_SLUG_IMMUTABLE: 'apiErrors.slugImmutable',
  NEWS_LOCALE_REQUIRED: 'apiErrors.localeRequired',
  NEWS_TITLE_REQUIRED: 'apiErrors.titleRequired',
  NEWS_EXCERPT_REQUIRED: 'apiErrors.excerptRequired',
  NEWS_BODY_REQUIRED: 'apiErrors.bodyRequired',
  NEWS_EMPTY_PARAGRAPH: 'apiErrors.emptyParagraph',
  NEWS_MEDIA_ID_REQUIRED: 'apiErrors.mediaIdRequired',
  NEWS_SCHEDULE_IN_PAST: 'apiErrors.scheduleInPast',
  NEWS_COVER_REQUIRED: 'apiErrors.coverRequired',
  NEWS_POST_NOT_FOUND: 'apiErrors.notFound',
  NEWS_INVALID_CATEGORY: 'apiErrors.invalidCategory',
  S3_NOT_CONFIGURED: 'apiErrors.s3NotConfigured',
};

export function newsApiErrorKey(error: unknown): string | null {
  if (error instanceof ApiError && error.code) {
    return CODE_TO_I18N[error.code] ?? null;
  }
  return null;
}

export function newsApiErrorMessage(
  error: unknown,
  t: (key: string) => string,
  fallback: string,
): string {
  const key = newsApiErrorKey(error);
  if (key) return t(key);
  if (error instanceof Error && error.message) return error.message;
  return fallback;
}
