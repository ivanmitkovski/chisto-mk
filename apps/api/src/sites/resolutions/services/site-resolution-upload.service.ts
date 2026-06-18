import {
  BadRequestException,
  Injectable,
  Logger,
  ServiceUnavailableException,
} from '@nestjs/common';
import { randomUUID } from 'crypto';
import { ImageContentValidator } from '../../../storage/util/image-content-validator';
import { S3StorageClient } from '../../../storage/util/s3-storage.client';
import { ReportsUploadService } from '../../../reports/services/reports-upload.service';
import { CITIZEN_IMAGE_UPLOAD_MAX_BYTES } from '../../../storage/constants/citizen-media-upload.constants';

const MAX_FILE_SIZE_BYTES = CITIZEN_IMAGE_UPLOAD_MAX_BYTES;

@Injectable()
export class SiteResolutionUploadService {
  private readonly logger = new Logger(SiteResolutionUploadService.name);

  constructor(
    private readonly s3: S3StorageClient,
    private readonly imageValidator: ImageContentValidator,
    private readonly reportsUpload: ReportsUploadService,
  ) {}

  async uploadFiles(
    userId: string,
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

    if (files.length > 5) {
      throw new BadRequestException({
        code: 'TOO_MANY_FILES',
        message: 'Maximum 5 files allowed',
      });
    }

    const urls: string[] = [];

    for (const file of files) {
      const { mime } = this.imageValidator.assertReportImage(file, {
        maxBytes: MAX_FILE_SIZE_BYTES,
      });
      const ext = mime === 'image/jpeg' || mime === 'image/jpg' ? 'jpg' : mime.split('/')[1] || 'jpg';
      const key = `site-resolutions/${userId}/${randomUUID()}.${ext}`;

      try {
        await this.s3.putObject({
          Key: key,
          Body: file.buffer,
          ContentType: mime,
        });
      } catch (err) {
        this.logger.warn(
          `site_resolution.upload s3_put_failed keyPrefix=site-resolutions/${userId}/ err=${(err as Error).message}`,
        );
        throw new ServiceUnavailableException({
          code: 'RESOLUTION_UPLOAD_STORAGE_ERROR',
          message: 'Could not store the image. Please try again shortly.',
        });
      }

      const base = this.s3.getVirtualHostedHttpsBase();
      urls.push(base ? `${base}${key}` : key);
    }

    return urls;
  }

  assertMediaUrlsFromOurBucket(urls: string[] | undefined): void {
    this.reportsUpload.assertReportMediaUrlsFromOurBucket(urls);
  }

  signUrls(urls: string[]): Promise<string[]> {
    return this.reportsUpload.signUrls(urls);
  }
}
