import {
  BadRequestException,
  Injectable,
  ServiceUnavailableException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { S3Client, PutObjectCommand, GetObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';

const ALLOWED_MIMES = new Set([
  'image/jpeg',
  'image/jpg',
  'image/png',
  'image/webp',
]);
const IMAGE_EXTENSIONS = /\.(jpe?g|png|webp)$/i;
const MAX_FILE_SIZE_BYTES = 10 * 1024 * 1024; // 10MB

@Injectable()
export class ReportsUploadService {
  private readonly s3: S3Client | null = null;
  private readonly bucket: string | null = null;
  private readonly region: string;
  private readonly enabled: boolean;
  private readonly signedUrlCache = new Map<string, { url: string; expiresAt: number }>();

  constructor(private readonly configService: ConfigService) {
    this.region =
      this.configService.get<string>('AWS_REGION')?.trim() ||
      this.configService.get<string>('AWS_DEFAULT_REGION')?.trim() ||
      'eu-central-1';
    const bucket = this.configService.get<string>('S3_BUCKET_NAME')?.trim();
    this.bucket = bucket && bucket.length > 0 ? bucket : null;
    this.enabled = !!this.bucket;
    if (this.enabled) {
      this.s3 = new S3Client({ region: this.region });
    }
  }

  async uploadFiles(
    userId: string,
    files: Array<{ buffer: Buffer; mimetype: string; size: number; originalname: string }>,
  ): Promise<string[]> {
    if (!this.enabled || !this.s3 || !this.bucket) {
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

    const timestamp = Date.now();
    const urls: string[] = [];

    for (const file of files) {
      let mime = (file.mimetype || '').toLowerCase();
      if (!ALLOWED_MIMES.has(mime)) {
        if (mime === 'application/octet-stream' && file.originalname) {
          const ext = file.originalname.match(IMAGE_EXTENSIONS)?.[1];
          if (ext) {
            mime = ext.startsWith('jpeg') || ext.startsWith('jpg')
              ? 'image/jpeg'
              : ext === 'png'
                ? 'image/png'
                : 'image/webp';
          }
        }
      }
      if (!ALLOWED_MIMES.has(mime)) {
        throw new BadRequestException({
          code: 'INVALID_FILE_TYPE',
          message: `Invalid file type: ${file.mimetype}. Only jpeg, png, and webp are allowed.`,
        });
      }

      if (file.size > MAX_FILE_SIZE_BYTES) {
        throw new BadRequestException({
          code: 'FILE_TOO_LARGE',
          message: `File ${file.originalname} exceeds 10MB limit`,
        });
      }

      const ext = mime === 'image/jpeg' || mime === 'image/jpg' ? 'jpg' : mime.split('/')[1] || 'jpg';
      const safeName = (file.originalname || 'image')
        .replace(/[^a-zA-Z0-9.-]/g, '_')
        .slice(0, 100) || 'image';
      const key = `reports/${userId}/${timestamp}-${safeName}.${ext}`;

      await this.s3.send(
        new PutObjectCommand({
          Bucket: this.bucket,
          Key: key,
          Body: file.buffer,
          ContentType: mime,
        }),
      );

      const url = `https://${this.bucket}.s3.${this.region}.amazonaws.com/${key}`;
      urls.push(url);
    }

    return urls;
  }

  /**
   * Converts S3 object URLs to presigned URLs (1h expiry) so clients can load
   * private objects. Non-S3 URLs are returned unchanged.
   */
  async signUrls(urls: string[]): Promise<string[]> {
    if (!this.enabled || !this.s3 || !this.bucket || !urls?.length) {
      return urls ?? [];
    }
    const base = `https://${this.bucket}.s3.${this.region}.amazonaws.com/`;
    const now = Date.now();
    const result: string[] = [];
    for (const url of urls) {
      if (typeof url !== 'string' || !url.startsWith(base)) {
        result.push(url);
        continue;
      }
      const key = decodeURIComponent(url.slice(base.length).split('?')[0]);
      const cacheHit = this.signedUrlCache.get(key);
      if (cacheHit && cacheHit.expiresAt > now) {
        result.push(cacheHit.url);
        continue;
      }
      try {
        const signed = await getSignedUrl(
          this.s3,
          new GetObjectCommand({ Bucket: this.bucket, Key: key }),
          { expiresIn: 3600 },
        );
        this.signedUrlCache.set(key, {
          url: signed,
          // Keep a safety buffer so we do not serve nearly-expired links.
          expiresAt: now + 50 * 60 * 1000,
        });
        result.push(signed);
      } catch {
        result.push(url);
      }
    }
    return result;
  }
}
