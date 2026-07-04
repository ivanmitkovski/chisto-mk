import { ApiError } from '@/lib/api/api';

const CODE_TO_I18N: Record<string, string> = {
  NEWS_SLUG_TAKEN: 'apiErrors.slugTaken',
  NEWS_INVALID_SLUG: 'apiErrors.invalidSlug',
  NEWS_SLUG_IMMUTABLE: 'apiErrors.slugImmutable',
  NEWS_POST_ARCHIVED: 'apiErrors.postArchived',
  NEWS_SCHEDULE_NOT_ALLOWED: 'apiErrors.scheduleNotAllowed',
  NEWS_POST_CONFLICT: 'apiErrors.postConflict',
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
  NEWS_FILE_REQUIRED: 'apiErrors.fileRequired',
  NEWS_INVALID_IMAGE_TYPE: 'apiErrors.invalidImageType',
  NEWS_INVALID_VIDEO_TYPE: 'apiErrors.invalidVideoType',
  NEWS_IMAGE_TOO_LARGE: 'apiErrors.imageTooLarge',
  NEWS_VIDEO_TOO_LARGE: 'apiErrors.videoTooLarge',
  NEWS_IMAGE_TOO_SMALL: 'apiErrors.imageTooSmall',
  NEWS_IMAGE_DIMENSIONS_TOO_LARGE: 'apiErrors.imageDimensionsTooLarge',
  NEWS_IMAGE_TYPE_MISMATCH: 'apiErrors.imageTypeMismatch',
  NEWS_INVALID_IMAGE: 'apiErrors.invalidImage',
  NEWS_UPLOAD_STORAGE_ERROR: 'apiErrors.uploadStorageError',
  NEWS_MEDIA_NOT_FOUND: 'apiErrors.mediaNotFound',
  NEWS_REVISION_NOT_FOUND: 'apiErrors.revisionNotFound',
  NEWS_BODY_TOO_MANY_BLOCKS: 'apiErrors.bodyTooManyBlocks',
  NEWS_PARAGRAPH_TOO_LONG: 'apiErrors.paragraphTooLong',
  NEWS_TITLE_TOO_LONG: 'apiErrors.titleTooLong',
  NEWS_EXCERPT_TOO_LONG: 'apiErrors.excerptTooLong',
  NEWS_INVALID_SCHEDULE: 'apiErrors.invalidSchedule',
  NEWS_COVER_MUST_BE_IMAGE: 'apiErrors.coverMustBeImage',
  NEWS_GALLERY_TOO_FEW_ITEMS: 'apiErrors.galleryTooFewItems',
  NEWS_INVALID_HEADING_LEVEL: 'apiErrors.invalidHeadingLevel',
  NEWS_ALT_TEXT_REQUIRED: 'apiErrors.altTextRequired',
  VALIDATION_ERROR: 'apiErrors.validationFailed',
  INVALID_FILE_TYPE: 'apiErrors.invalidImageType',
  FILE_TOO_LARGE: 'apiErrors.imageTooLarge',
  MIME_TYPE_MISMATCH: 'apiErrors.imageTypeMismatch',
  IMAGE_TOO_SMALL: 'apiErrors.imageTooSmall',
  IMAGE_TOO_LARGE: 'apiErrors.imageDimensionsTooLarge',
  INVALID_IMAGE: 'apiErrors.invalidImage',
  PAYLOAD_TOO_LARGE: 'apiErrors.payloadTooLarge',
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
