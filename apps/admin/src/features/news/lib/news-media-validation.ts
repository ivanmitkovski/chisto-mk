import {
  NEWS_COVER_MAX_BYTES,
  NEWS_INLINE_IMAGE_MAX_BYTES,
  NEWS_SVG_MAX_BYTES,
  NEWS_VIDEO_MAX_BYTES,
  newsRasterImageMaxBytes,
  newsRasterImageMaxMb,
} from '@chisto/news-content';

export {
  NEWS_COVER_MAX_BYTES,
  NEWS_INLINE_IMAGE_MAX_BYTES,
  NEWS_SVG_MAX_BYTES,
  NEWS_VIDEO_MAX_BYTES,
  newsRasterImageMaxBytes,
  newsRasterImageMaxMb,
};

/** @deprecated Use NEWS_INLINE_IMAGE_MAX_BYTES or newsRasterImageMaxBytes(kind). */
export const NEWS_IMAGE_MAX_BYTES = NEWS_INLINE_IMAGE_MAX_BYTES;

export const NEWS_IMAGE_MIN_DIMENSION = 128;

const IMAGE_MIMES = new Set([
  'image/jpeg',
  'image/jpg',
  'image/png',
  'image/webp',
  'image/heic',
  'image/heif',
  'image/svg+xml',
]);

const VIDEO_MIMES = new Set(['video/mp4', 'video/quicktime', 'video/webm']);

export type NewsMediaKind = 'cover' | 'inline_image' | 'inline_video';

export type NewsMediaValidationCode =
  | 'invalidImageType'
  | 'invalidVideoType'
  | 'imageTooLarge'
  | 'videoTooLarge'
  | 'imageTooSmall'
  | 'imageDimensionsUnreadable';

export type NewsMediaValidationResult =
  | { ok: true }
  | { ok: false; code: NewsMediaValidationCode; maxMb?: number };

export const NEWS_MEDIA_ACCEPT = {
  cover: 'image/jpeg,image/png,image/webp,image/heic,image/heif,image/svg+xml,.heic,.svg',
  inline_image: 'image/jpeg,image/png,image/webp,image/heic,image/heif,image/svg+xml,.heic,.svg',
  inline_video: 'video/mp4,video/webm,video/quicktime,.mp4,.webm,.mov',
} as const;

function isSvgFile(file: File): boolean {
  const mime = file.type.toLowerCase();
  if (mime === 'image/svg+xml') return true;
  return file.name.split('.').pop()?.toLowerCase() === 'svg';
}

function isImageFile(file: File): boolean {
  const mime = file.type.toLowerCase();
  if (IMAGE_MIMES.has(mime)) return true;
  const ext = file.name.split('.').pop()?.toLowerCase();
  return ext === 'heic' || ext === 'heif' || ext === 'svg';
}

function isVideoFile(file: File): boolean {
  const mime = file.type.toLowerCase();
  if (VIDEO_MIMES.has(mime)) return true;
  const ext = file.name.split('.').pop()?.toLowerCase();
  return ext === 'mp4' || ext === 'webm' || ext === 'mov';
}

function rasterMaxMb(kind: 'cover' | 'inline_image'): number {
  return Math.round(newsRasterImageMaxBytes(kind) / (1024 * 1024));
}

export async function validateNewsMediaFile(
  file: File,
  kind: NewsMediaKind,
): Promise<NewsMediaValidationResult> {
  if (kind === 'inline_video') {
    if (!isVideoFile(file)) {
      return { ok: false, code: 'invalidVideoType' };
    }
    if (file.size > NEWS_VIDEO_MAX_BYTES) {
      return {
        ok: false,
        code: 'videoTooLarge',
        maxMb: Math.round(NEWS_VIDEO_MAX_BYTES / (1024 * 1024)),
      };
    }
    return { ok: true };
  }

  if (!isImageFile(file)) {
    return { ok: false, code: 'invalidImageType' };
  }

  if (isSvgFile(file)) {
    if (file.size > NEWS_SVG_MAX_BYTES) {
      return {
        ok: false,
        code: 'imageTooLarge',
        maxMb: Math.round(NEWS_SVG_MAX_BYTES / (1024 * 1024)),
      };
    }
    return { ok: true };
  }

  const maxBytes = newsRasterImageMaxBytes(kind);
  if (file.size > maxBytes) {
    return { ok: false, code: 'imageTooLarge', maxMb: rasterMaxMb(kind) };
  }

  const heic =
    file.type.toLowerCase() === 'image/heic' ||
    file.type.toLowerCase() === 'image/heif' ||
    file.name.toLowerCase().endsWith('.heic') ||
    file.name.toLowerCase().endsWith('.heif');
  if (heic) {
    return { ok: true };
  }

  try {
    const dims = await readImageDimensions(file);
    if (dims.width < NEWS_IMAGE_MIN_DIMENSION || dims.height < NEWS_IMAGE_MIN_DIMENSION) {
      return { ok: false, code: 'imageTooSmall' };
    }
  } catch {
    return { ok: false, code: 'imageDimensionsUnreadable' };
  }

  return { ok: true };
}

function readImageDimensions(file: File): Promise<{ width: number; height: number }> {
  return new Promise((resolve, reject) => {
    const url = URL.createObjectURL(file);
    const img = new Image();
    img.onload = () => {
      URL.revokeObjectURL(url);
      resolve({ width: img.naturalWidth, height: img.naturalHeight });
    };
    img.onerror = () => {
      URL.revokeObjectURL(url);
      reject(new Error('unreadable'));
    };
    img.src = url;
  });
}

export function newsMediaValidationMessageKey(code: NewsMediaValidationCode): string {
  return `mediaValidation.${code}`;
}

export function newsMediaValidationMessage(
  translate: (key: string, values?: Record<string, number>) => string,
  result: Extract<NewsMediaValidationResult, { ok: false }>,
): string {
  const key = newsMediaValidationMessageKey(result.code);
  if (result.maxMb != null) {
    return translate(key, { maxMb: result.maxMb });
  }
  return translate(key);
}
