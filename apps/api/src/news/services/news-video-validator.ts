import { BadRequestException } from '@nestjs/common';

const VIDEO_MIMES = new Set(['video/mp4', 'video/quicktime', 'video/webm']);

export function assertNewsVideoFile(
  file: { buffer: Buffer; mimetype: string; size: number; originalname?: string },
  maxBytes: number,
): { mime: string; ext: string } {
  const mime = resolveVideoMime(file.mimetype, file.originalname ?? '');
  if (!mime) {
    throw new BadRequestException({
      code: 'NEWS_INVALID_VIDEO_TYPE',
      message: 'Video must be MP4, MOV, or WebM',
    });
  }
  if (file.size > maxBytes) {
    throw new BadRequestException({
      code: 'NEWS_VIDEO_TOO_LARGE',
      message: 'Video exceeds maximum size',
    });
  }
  if (!detectVideoMagicBytes(file.buffer, mime)) {
    throw new BadRequestException({
      code: 'NEWS_INVALID_VIDEO_TYPE',
      message: 'Video must be MP4, MOV, or WebM',
    });
  }
  const ext = mime === 'video/quicktime' ? 'mov' : mime.split('/')[1] || 'mp4';
  return { mime, ext };
}

function resolveVideoMime(mimetype: string, originalname: string): string | null {
  const mime = mimetype?.toLowerCase() ?? '';
  if (VIDEO_MIMES.has(mime)) {
    return mime;
  }
  const ext = originalname.split('.').pop()?.toLowerCase();
  if (ext === 'mp4') return 'video/mp4';
  if (ext === 'mov') return 'video/quicktime';
  if (ext === 'webm') return 'video/webm';
  return null;
}

function detectVideoMagicBytes(buffer: Buffer, mime: string): boolean {
  if (buffer.length < 4) {
    return false;
  }
  if (mime === 'video/webm') {
    return (
      buffer[0] === 0x1a &&
      buffer[1] === 0x45 &&
      buffer[2] === 0xdf &&
      buffer[3] === 0xa3
    );
  }
  if (buffer.length < 8) {
    return false;
  }
  return buffer.subarray(4, 8).toString('ascii') === 'ftyp';
}
