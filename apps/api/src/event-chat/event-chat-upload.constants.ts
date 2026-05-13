/** MIME/size caps mirror mobile `ChatUploadLimits` (apps/mobile/.../chat_upload_limits.dart). */
export const IMAGE_MIMES = new Set([
  'image/jpeg',
  'image/jpg',
  'image/png',
  'image/webp',
  'image/heic',
]);

export const VIDEO_MIMES = new Set([
  'video/mp4',
  'video/quicktime',
  'video/webm',
]);

export const AUDIO_MIMES = new Set([
  'audio/mpeg',
  'audio/mp3',
  'audio/aac',
  'audio/m4a',
  'audio/ogg',
  'audio/wav',
]);

export const DOC_MIMES = new Set([
  'application/pdf',
  'application/msword',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  'application/vnd.openxmlformats-officedocument.presentationml.presentation',
  'text/plain',
]);

export const ALL_ALLOWED_MIMES = new Set([...IMAGE_MIMES, ...VIDEO_MIMES, ...AUDIO_MIMES, ...DOC_MIMES]);

export const MAX_IMAGE_SIZE = 10 * 1024 * 1024;
export const MAX_VIDEO_SIZE = 25 * 1024 * 1024;
export const MAX_AUDIO_SIZE = 10 * 1024 * 1024;
export const MAX_DOC_SIZE = 10 * 1024 * 1024;
export const MAX_FILES_PER_MESSAGE = 5;

/** Multer per-file cap (largest allowed type is video). */
export const EVENT_CHAT_MULTER_MAX_FILE_BYTES = MAX_VIDEO_SIZE;

export function maxSizeForMime(mime: string): number {
  if (VIDEO_MIMES.has(mime)) return MAX_VIDEO_SIZE;
  if (AUDIO_MIMES.has(mime)) return MAX_AUDIO_SIZE;
  if (DOC_MIMES.has(mime)) return MAX_DOC_SIZE;
  return MAX_IMAGE_SIZE;
}
