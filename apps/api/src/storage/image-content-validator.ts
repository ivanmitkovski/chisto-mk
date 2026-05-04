import { BadRequestException, Injectable } from '@nestjs/common';
import { imageSize } from 'image-size';
import { detectAllowedImageMimeFromBuffer } from '../common/utils/detect-allowed-image-mime-from-buffer';

const ALLOWED_MIMES = new Set(['image/jpeg', 'image/jpg', 'image/png', 'image/webp']);

export type ImageUploadFile = {
  buffer: Buffer;
  mimetype: string;
  size: number;
  originalname: string;
};

/**
 * Validates uploaded image buffers using magic bytes + header-based dimensions (fast).
 * Keeps report/cleanup upload rules aligned across modules.
 */
@Injectable()
export class ImageContentValidator {
  assertReportImage(
    file: ImageUploadFile,
    options: { maxBytes: number; maxFilesHint?: number },
  ): { mime: string } {
    if (!file?.buffer || file.size <= 0) {
      throw new BadRequestException({
        code: 'FILE_REQUIRED',
        message: 'Image file is required.',
      });
    }
    if (file.size > options.maxBytes) {
      throw new BadRequestException({
        code: 'FILE_TOO_LARGE',
        message: `File exceeds ${Math.round(options.maxBytes / (1024 * 1024))}MB limit`,
      });
    }

    const sample = file.buffer.subarray(0, Math.min(file.buffer.length, 4096));
    const mime = detectAllowedImageMimeFromBuffer(sample);
    if (!mime || !ALLOWED_MIMES.has(mime)) {
      throw new BadRequestException({
        code: 'INVALID_FILE_TYPE',
        message: 'Invalid file type. Only jpeg, png, and webp images are allowed.',
      });
    }

    const declared = (file.mimetype || '').toLowerCase();
    if (
      declared &&
      declared !== 'application/octet-stream' &&
      declared !== mime &&
      !(declared === 'image/jpg' && mime === 'image/jpeg')
    ) {
      throw new BadRequestException({
        code: 'MIME_TYPE_MISMATCH',
        message: 'File content does not match the declared type.',
      });
    }

    let width = 0;
    let height = 0;
    try {
      const dim = imageSize(file.buffer as Uint8Array);
      width = dim.width ?? 0;
      height = dim.height ?? 0;
    } catch {
      throw new BadRequestException({
        code: 'INVALID_IMAGE',
        message: 'Could not read image dimensions.',
      });
    }

    if (width < 128 || height < 128) {
      throw new BadRequestException({
        code: 'IMAGE_TOO_SMALL',
        message: 'Image must be at least 128×128 pixels.',
      });
    }
    if (width > 8192 || height > 8192) {
      throw new BadRequestException({
        code: 'IMAGE_TOO_LARGE',
        message: 'Image dimensions must not exceed 8192×8192 pixels.',
      });
    }

    return { mime };
  }
}
