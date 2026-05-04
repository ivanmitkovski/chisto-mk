import { BadRequestException, Injectable, ServiceUnavailableException } from '@nestjs/common';
import { randomUUID } from 'crypto';
import { ImageContentValidator } from '../storage/image-content-validator';
import { S3StorageClient } from '../storage/s3-storage.client';

const MAX_FILE_SIZE_BYTES = 10 * 1024 * 1024;

/**
 * After-cleanup event photos — lives in events bounded context (not reports).
 */
@Injectable()
export class EventsCleanupMediaUploadService {
  constructor(
    private readonly s3: S3StorageClient,
    private readonly images: ImageContentValidator,
  ) {}

  async uploadCleanupEventAfterImages(
    userId: string,
    eventId: string,
    files: Array<{ buffer: Buffer; mimetype: string; size: number; originalname: string }>,
  ): Promise<string[]> {
    if (!this.s3.enabled) {
      throw new ServiceUnavailableException({
        code: 'S3_NOT_CONFIGURED',
        message: 'File upload is not configured. S3_BUCKET_NAME is required.',
      });
    }

    if (!files || files.length === 0) {
      return [];
    }

    if (files.length > 10) {
      throw new BadRequestException({
        code: 'TOO_MANY_FILES',
        message: 'Maximum 10 after-cleanup photos allowed',
      });
    }

    const keys: string[] = [];
    const baseTs = Date.now();

    for (let i = 0; i < files.length; i++) {
      const file = files[i];
      const { mime } = this.images.assertReportImage(file, { maxBytes: MAX_FILE_SIZE_BYTES });
      const ext = mime === 'image/jpeg' || mime === 'image/jpg' ? 'jpg' : mime.split('/')[1] || 'jpg';
      const key = `cleanup-events/${userId}/${eventId}/${baseTs}-${i}-${randomUUID()}.${ext}`;

      await this.s3.putObject({
        Key: key,
        Body: file.buffer,
        ContentType: mime,
      });

      keys.push(key);
    }

    return keys;
  }
}
