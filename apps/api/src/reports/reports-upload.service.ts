import {
  BadRequestException,
  Injectable,
  Logger,
  ServiceUnavailableException,
} from '@nestjs/common';
import { randomUUID } from 'crypto';
import { ObservabilityStore } from '../observability/observability.store';
import { ImageContentValidator } from '../storage/image-content-validator';
import { ReportMediaSignedUrlService } from '../storage/report-media-signed-url.service';
import { S3StorageClient } from '../storage/s3-storage.client';
import { UsersAvatarService } from '../users/users-avatar.service';

const MAX_FILE_SIZE_BYTES = 10 * 1024 * 1024;

@Injectable()
export class ReportsUploadService {
  private readonly logger = new Logger(ReportsUploadService.name);

  constructor(
    private readonly s3: S3StorageClient,
    private readonly imageValidator: ImageContentValidator,
    private readonly reportSignedUrls: ReportMediaSignedUrlService,
    private readonly usersAvatar: UsersAvatarService,
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
      const { mime } = this.imageValidator.assertReportImage(file, { maxBytes: MAX_FILE_SIZE_BYTES });
      const ext = mime === 'image/jpeg' || mime === 'image/jpg' ? 'jpg' : mime.split('/')[1] || 'jpg';
      const key = `reports/${userId}/${randomUUID()}.${ext}`;

      try {
        await this.s3.putObject({
          Key: key,
          Body: file.buffer,
          ContentType: mime,
        });
        ObservabilityStore.recordReportUpload('success');
      } catch (err) {
        ObservabilityStore.recordReportUpload('error');
        this.logger.warn(
          `report.upload s3_put_failed keyPrefix=reports/${userId}/ err=${(err as Error).message}`,
        );
        throw new ServiceUnavailableException({
          code: 'REPORT_UPLOAD_STORAGE_ERROR',
          message: 'Could not store the image. Please try again shortly.',
        });
      }

      const base = this.s3.getVirtualHostedHttpsBase();
      if (!base) {
        urls.push(key);
      } else {
        urls.push(`${base}${key}`);
      }
    }

    return urls;
  }

  getPublicUrlsForKeys(keys: string[]): string[] {
    if (!this.s3.bucket) {
      return keys;
    }
    const base = this.s3.getVirtualHostedHttpsBase();
    if (!base) {
      return keys;
    }
    return keys.map((key) => `${base}${key}`);
  }

  /**
   * Ensures submit/append media URLs were issued by this API's upload path (same bucket + virtual host).
   */
  assertReportMediaUrlsFromOurBucket(urls: string[] | undefined): void {
    if (!urls?.length) {
      return;
    }
    const base = this.s3.getVirtualHostedHttpsBase();
    if (!base) {
      throw new ServiceUnavailableException({
        code: 'S3_NOT_CONFIGURED',
        message: 'Cannot validate media URLs while file storage is disabled',
      });
    }
    for (const raw of urls) {
      const u = typeof raw === 'string' ? raw.trim() : '';
      if (!u.startsWith(base)) {
        throw new BadRequestException({
          code: 'INVALID_MEDIA_URL',
          message: 'Each media URL must come from the configured report upload endpoint',
        });
      }
    }
  }

  normalizeReportMediaRefToCanonicalHttpsUrl(ref: string): string {
    const t = ref.trim();
    if (!t) {
      return t;
    }
    if (t.startsWith('http://') || t.startsWith('https://')) {
      return t;
    }
    const base = this.s3.getVirtualHostedHttpsBase();
    if (!base) {
      return t;
    }
    const key = t.replace(/^\//, '');
    return `${base}${key}`;
  }

  async signUrls(urls: string[]): Promise<string[]> {
    if (!urls?.length) {
      return [];
    }
    if (!this.s3.enabled) {
      return urls
        .filter((u): u is string => typeof u === 'string')
        .map((u) => this.normalizeReportMediaRefToCanonicalHttpsUrl(u.trim()));
    }
    const base = this.s3.getVirtualHostedHttpsBase();
    if (!base) {
      return urls
        .filter((u): u is string => typeof u === 'string')
        .map((u) => this.normalizeReportMediaRefToCanonicalHttpsUrl(u.trim()));
    }
    const result: string[] = [];
    for (const url of urls) {
      if (typeof url !== 'string') {
        continue;
      }
      const canonical = this.normalizeReportMediaRefToCanonicalHttpsUrl(url.trim());
      if (!canonical) {
        continue;
      }
      if (!canonical.startsWith(base)) {
        result.push(canonical);
        continue;
      }
      const key = decodeURIComponent(canonical.slice(base.length).split('?')[0]);
      const signed = await this.reportSignedUrls.getSignedGetUrl(key);
      result.push(signed ?? canonical);
    }
    return result;
  }

  uploadProfileAvatar(
    userId: string,
    file: { buffer: Buffer; mimetype: string; size: number; originalname: string },
  ): Promise<string> {
    return this.usersAvatar.uploadProfileAvatar(userId, file);
  }

  signPrivateObjectKey(objectKey: string | null | undefined): Promise<string | null> {
    return this.usersAvatar.signPrivateObjectKey(objectKey);
  }

  resolveUserAvatarUrl(stored: string | null | undefined): Promise<string | null> {
    return this.usersAvatar.resolveUserAvatarUrl(stored);
  }

  async deleteObjectByKey(objectKey: string | null | undefined): Promise<void> {
    if (!objectKey || !this.s3.enabled) {
      return;
    }
    this.reportSignedUrls.invalidateKey(objectKey);
    this.usersAvatar.invalidateSignedUrlCacheForKey(objectKey);
    try {
      await this.s3.deleteObject(objectKey);
    } catch (err) {
      this.logger.warn(`S3 delete failed for key=${objectKey}: ${(err as Error).message}`);
    }
  }

  tryExtractReportMediaObjectKeyFromUrl(url: string | null | undefined): string | null {
    if (!url || !this.s3.bucket) {
      return null;
    }
    const base = this.s3.getVirtualHostedHttpsBase();
    if (!base || !url.startsWith(base)) {
      return null;
    }
    return decodeURIComponent(url.slice(base.length).split('?')[0]);
  }

  async deleteReportMediaUrls(urls: string[] | null | undefined): Promise<number> {
    if (!urls?.length) {
      return 0;
    }
    const uniqueKeys = new Set<string>();
    for (const url of urls) {
      const key = this.tryExtractReportMediaObjectKeyFromUrl(url);
      if (key) {
        uniqueKeys.add(key);
      }
    }
    let deleted = 0;
    for (const key of uniqueKeys) {
      try {
        await this.deleteObjectByKey(key);
        deleted += 1;
      } catch (err) {
        this.logger.warn(`S3 delete failed for report media key=${key}: ${(err as Error).message}`);
      }
    }
    return deleted;
  }
}
