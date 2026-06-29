import { BadRequestException, Injectable } from '@nestjs/common';
import { imageSize } from 'image-size';
import sharp from 'sharp';
import { detectAllowedImageMimeFromBuffer } from '../../common/utils/detect-allowed-image-mime-from-buffer';
import { detectHeicFromBuffer, isHeicMime } from '../../common/utils/detect-heic-from-buffer';

const MIN_DIMENSION = 128;
const MAX_DIMENSION = 8192;
const HEIC_WEBP_QUALITY = 85;

export type NewsImageUploadFile = {
  buffer: Buffer;
  mimetype: string;
  size: number;
  originalname: string;
};

export type ProcessedNewsImage = {
  buffer: Buffer;
  mime: string;
  ext: string;
  width: number;
  height: number;
};

@Injectable()
export class NewsImageProcessor {
  async process(file: NewsImageUploadFile, maxBytes: number): Promise<ProcessedNewsImage> {
    if (!file?.buffer || file.size <= 0) {
      throw new BadRequestException({
        code: 'NEWS_FILE_REQUIRED',
        message: 'File is required',
      });
    }
    if (file.size > maxBytes) {
      throw new BadRequestException({
        code: 'NEWS_IMAGE_TOO_LARGE',
        message: `Image exceeds ${Math.round(maxBytes / (1024 * 1024))}MB limit`,
      });
    }

    const declared = (file.mimetype || '').toLowerCase();
    const sample = file.buffer.subarray(0, Math.min(file.buffer.length, 4096));
    const isHeic = isHeicMime(declared) || detectHeicFromBuffer(sample);

    if (isHeic) {
      return this.processHeic(file.buffer);
    }

    const detected = detectAllowedImageMimeFromBuffer(sample);
    if (!detected) {
      throw new BadRequestException({
        code: 'NEWS_INVALID_IMAGE_TYPE',
        message: 'Image must be JPEG, PNG, WebP, or HEIC',
      });
    }

    if (
      declared &&
      declared !== 'application/octet-stream' &&
      declared !== detected &&
      !(declared === 'image/jpg' && detected === 'image/jpeg') &&
      !isHeicMime(declared)
    ) {
      throw new BadRequestException({
        code: 'NEWS_IMAGE_TYPE_MISMATCH',
        message: 'File content does not match the declared type',
      });
    }

    const { width, height } = this.readDimensions(file.buffer);
    this.assertDimensions(width, height);

    const ext =
      detected === 'image/jpeg' || detected === 'image/jpg'
        ? 'jpg'
        : detected.split('/')[1] || 'jpg';

    return {
      buffer: file.buffer,
      mime: detected,
      ext,
      width,
      height,
    };
  }

  private async processHeic(buffer: Buffer): Promise<ProcessedNewsImage> {
    try {
      const image = sharp(buffer);
      const meta = await image.metadata();
      const width = meta.width ?? 0;
      const height = meta.height ?? 0;
      this.assertDimensions(width, height);
      const webp = await image.webp({ quality: HEIC_WEBP_QUALITY }).toBuffer();
      return {
        buffer: webp,
        mime: 'image/webp',
        ext: 'webp',
        width,
        height,
      };
    } catch {
      throw new BadRequestException({
        code: 'NEWS_INVALID_IMAGE',
        message: 'Could not process HEIC image',
      });
    }
  }

  private readDimensions(buffer: Buffer): { width: number; height: number } {
    try {
      const dim = imageSize(buffer as Uint8Array);
      return { width: dim.width ?? 0, height: dim.height ?? 0 };
    } catch {
      throw new BadRequestException({
        code: 'NEWS_INVALID_IMAGE',
        message: 'Could not read image dimensions',
      });
    }
  }

  private assertDimensions(width: number, height: number): void {
    if (width < MIN_DIMENSION || height < MIN_DIMENSION) {
      throw new BadRequestException({
        code: 'NEWS_IMAGE_TOO_SMALL',
        message: 'Image must be at least 128×128 pixels',
      });
    }
    if (width > MAX_DIMENSION || height > MAX_DIMENSION) {
      throw new BadRequestException({
        code: 'NEWS_IMAGE_DIMENSIONS_TOO_LARGE',
        message: 'Image dimensions must not exceed 8192×8192 pixels',
      });
    }
  }
}
