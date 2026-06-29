import { BadRequestException } from '@nestjs/common';
import type { NewsMediaKind } from '../../prisma-client';
import { NewsImageProcessor } from './news-image-processor';
import { assertNewsVideoFile } from './news-video-validator';

export const NEWS_MAX_IMAGE_BYTES = 10 * 1024 * 1024;
export const NEWS_MAX_VIDEO_BYTES = 25 * 1024 * 1024;

const VIDEO_MIMES = new Set(['video/mp4', 'video/quicktime', 'video/webm']);

export type NewsMediaUploadKind = 'cover' | 'inline_image' | 'inline_video';

export type ProcessedNewsMediaFile = {
  body: Buffer;
  mime: string;
  ext: string;
  width: number | null;
  height: number | null;
};

export function toNewsMediaPrismaKind(kind: NewsMediaUploadKind): NewsMediaKind {
  switch (kind) {
    case 'cover':
      return 'COVER';
    case 'inline_image':
      return 'INLINE_IMAGE';
    case 'inline_video':
      return 'INLINE_VIDEO';
  }
}

export async function validateAndProcessNewsMediaFile(
  imageProcessor: NewsImageProcessor,
  kind: NewsMediaUploadKind,
  file: { buffer: Buffer; mimetype: string; size: number; originalname: string },
): Promise<ProcessedNewsMediaFile> {
  const mime = file.mimetype?.toLowerCase() ?? '';
  if (kind === 'cover' && VIDEO_MIMES.has(mime)) {
    throw new BadRequestException({
      code: 'NEWS_COVER_MUST_BE_IMAGE',
      message: 'Cover must be an image file',
    });
  }
  if (kind === 'inline_video') {
    const video = assertNewsVideoFile(file, NEWS_MAX_VIDEO_BYTES);
    return {
      body: file.buffer,
      mime: video.mime,
      ext: video.ext,
      width: null,
      height: null,
    };
  }

  const image = await imageProcessor.process(file, NEWS_MAX_IMAGE_BYTES);
  return {
    body: image.buffer,
    mime: image.mime,
    ext: image.ext,
    width: image.width,
    height: image.height,
  };
}
